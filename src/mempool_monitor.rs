use ethers::{
    prelude::*,
    providers::{Provider, Ws},
    types::{Transaction, H160},
};
use futures::StreamExt;
use std::sync::Arc;
use tokio::sync::Mutex;
use chrono::Utc;
use tokio::task::JoinHandle;
use std::time::Duration;
use std::collections::HashMap;

use crate::{
    config::Config,
    transaction_stats::{TransactionStats, SharedStats},
    conversions::{wei_to_eth, wei_to_gwei},
};

// Known DEX router addresses on BSC
const DEX_ROUTERS: [&str; 3] = [
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // PancakeSwap V2
    "0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F", // PancakeSwap V1
    "0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8", // ApeSwap
];

// Known MEV bot addresses
const MEV_BOTS: [&str; 5] = [
    "0x0000000000007F150Bd6f54c40A34d7C3d5e9f56", // Common MEV bot
    "0x000000000000084e91743124a982076C59f10084", // Another common MEV bot
    "0x0000000000000000000000000000000000000000", // Add more known MEV bots
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
];

pub struct MempoolMonitor {
    config: Config,
    stats: SharedStats,
    worker_handles: Vec<JoinHandle<()>>,
    // Track recent transactions for sandwich detection
    recent_transactions: Arc<Mutex<HashMap<H160, Vec<Transaction>>>>,
}

impl MempoolMonitor {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            stats: Arc::new(Mutex::new(TransactionStats::new())),
            worker_handles: Vec::new(),
            recent_transactions: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub async fn start(&mut self) -> eyre::Result<()> {
        println!("Connecting to BSC node at {}", self.config.ws_url);

        // Connect to the node
        let ws = Ws::connect_with_reconnects(&self.config.ws_url, 5).await?;
        let provider = Provider::new(ws);
        let provider = Arc::new(provider);

        // Start statistics reporting
        self.start_stats_reporting();

        // Start worker threads
        let num_workers = num_cpus::get(); // Use number of CPU cores
        println!("Starting {} worker threads for transaction processing", num_workers);
        
        // Create channels for each worker
        let mut worker_senders = Vec::with_capacity(num_workers);
        let mut worker_receivers = Vec::with_capacity(num_workers);
        
        for _ in 0..num_workers {
            let (tx, rx) = tokio::sync::mpsc::channel(1000); // Buffer size of 1000 transactions
            worker_senders.push(tx);
            worker_receivers.push(rx);
        }
        
        // Start workers
        for (worker_id, mut rx) in worker_receivers.into_iter().enumerate() {
            let stats = self.stats.clone();
            let provider = provider.clone();
            let recent_txs = self.recent_transactions.clone();
            
            let handle = tokio::spawn(async move {
                println!("Worker {} started", worker_id);
                while let Some(tx_hash) = rx.recv().await {
                    if let Ok(Some(tx)) = provider.get_transaction(tx_hash).await {
                        Self::process_transaction(&stats, &recent_txs, &tx).await;
                    }
                }
            });
            
            self.worker_handles.push(handle);
        }

        // Subscribe to pending transactions and distribute to workers
        let mut stream = provider.subscribe_pending_txs().await?;
        println!("Successfully subscribed to pending transactions");

        let mut worker_index = 0;
        while let Some(tx_hash) = stream.next().await {
            // Round-robin distribution of transactions to workers
            if let Err(e) = worker_senders[worker_index].send(tx_hash).await {
                eprintln!("Error sending transaction to worker {}: {}", worker_index, e);
            }
            worker_index = (worker_index + 1) % num_workers;
        }

        Ok(())
    }

    fn start_stats_reporting(&self) {
        let stats = self.stats.clone();
        let interval = self.config.report_interval;
        
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(interval));
            loop {
                interval.tick().await;
                let stats_snapshot = stats.lock().await.clone();
                
                println!("\n---------- MEMPOOL STATISTICS ----------");
                println!("Transactions seen: {}", stats_snapshot.count());
                println!("Transactions per second: {:.2}", stats_snapshot.transactions_per_second());
                println!("Min gas price: {} gwei", wei_to_gwei(stats_snapshot.min_gas_price()));
                println!("Max gas price: {} gwei", wei_to_gwei(stats_snapshot.max_gas_price()));
                println!("Avg gas price: {} gwei", wei_to_gwei(stats_snapshot.avg_gas_price()));
                println!("Total value: {} BNB", wei_to_eth(stats_snapshot.value_total()));
                println!("---------------------------------------\n");
            }
        });
    }

    async fn process_transaction(stats: &SharedStats, recent_txs: &Arc<Mutex<HashMap<H160, Vec<Transaction>>>>, tx: &Transaction) {
        let is_dex_router = DEX_ROUTERS.contains(&tx.to.unwrap_or_default().to_string().as_str());
        let is_mev_bot = MEV_BOTS.contains(&tx.from.to_string().as_str());
        let gas_price = wei_to_gwei(tx.gas_price.unwrap_or_default());
        let value = wei_to_eth(tx.value);

        // Check for potential frontrunning opportunities
        let mut is_frontrunnable = false;
        let mut frontrun_reason = String::new();

        if is_dex_router {
            is_frontrunnable = true;
            frontrun_reason.push_str("DEX Swap");
        }

        if value > 1.0 {
            is_frontrunnable = true;
            frontrun_reason.push_str(&format!(" | High Value: {} BNB", value));
        }

        if gas_price > 5.0 {
            is_frontrunnable = true;
            frontrun_reason.push_str(&format!(" | High Gas: {} gwei", gas_price));
        }

        if is_mev_bot {
            is_frontrunnable = true;
            frontrun_reason.push_str(" | MEV Bot");
        }

        // Print transaction with frontrunning indicators
        println!("\n[{}] ===== NEW TRANSACTION =====", Utc::now().format("%H:%M:%S"));
        if is_frontrunnable {
            println!("🚨 POTENTIAL FRONTRUN OPPORTUNITY 🚨");
            println!("Reason: {}", frontrun_reason);
        }
        println!("  Hash: {:?}", tx.hash);
        println!("  From: {:?}", tx.from);
        println!("  To: {:?}", tx.to);
        println!("  Value: {} BNB", value);
        println!("  Gas Price: {} gwei", gas_price);
        println!("  Gas Limit: {}", tx.gas);
        println!("  Nonce: {}", tx.nonce);
        if is_dex_router {
            println!("  Type: DEX Router Interaction");
        }
        if is_mev_bot {
            println!("  Type: MEV Bot Transaction");
        }
        println!("  ============================");

        // Update stats
        let mut stats_lock = stats.lock().await;
        stats_lock.update(tx);

        // Update recent transactions for sandwich detection
        if let Some(to) = tx.to {
            let mut recent_txs_lock = recent_txs.lock().await;
            let txs = recent_txs_lock.entry(to).or_insert_with(Vec::new);
            txs.push(tx.clone());
            
            // Keep only last 10 transactions per address
            if txs.len() > 10 {
                txs.remove(0);
            }
        }
    }
} 