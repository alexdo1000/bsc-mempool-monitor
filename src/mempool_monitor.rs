use ethers::{
    prelude::*,
    providers::{Provider, Ws},
    types::Transaction,
};
use futures::StreamExt;
use std::sync::Arc;
use tokio::sync::Mutex;
use chrono::Utc;
use tokio::task::JoinHandle;
use std::time::Duration;

use crate::{
    config::Config,
    transaction_stats::{TransactionStats, SharedStats},
    conversions::{wei_to_eth, wei_to_gwei},
};

pub struct MempoolMonitor {
    config: Config,
    stats: SharedStats,
    worker_handles: Vec<JoinHandle<()>>,
}

impl MempoolMonitor {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            stats: Arc::new(Mutex::new(TransactionStats::new())),
            worker_handles: Vec::new(),
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
            
            let handle = tokio::spawn(async move {
                println!("Worker {} started", worker_id);
                while let Some(tx_hash) = rx.recv().await {
                    if let Ok(Some(tx)) = provider.get_transaction(tx_hash).await {
                        Self::process_transaction(&stats, &tx).await;
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

    async fn process_transaction(stats: &SharedStats, tx: &Transaction) {
        println!("[{}] ===== NEW TRANSACTION =====", Utc::now().format("%H:%M:%S"));
        println!("  Hash: {:?}", tx.hash);
        println!("  From: {:?}", tx.from);
        println!("  To: {:?}", tx.to);
        println!("  Value: {} BNB", wei_to_eth(tx.value));
        println!("  Gas Price: {} gwei", wei_to_gwei(tx.gas_price.unwrap_or_default()));
        println!("  Gas Limit: {}", tx.gas);
        println!("  Nonce: {}", tx.nonce);
        println!("  ============================");

        // Update stats
        let mut stats_lock = stats.lock().await;
        stats_lock.update(tx);
    }
} 