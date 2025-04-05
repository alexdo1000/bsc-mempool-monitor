use ethers::{
    prelude::*,
    providers::{Middleware, Provider, Ws},
    types::{Transaction, U256},
};
use futures::StreamExt;
use std::sync::Arc;
use tokio::sync::Mutex;
use chrono::{Utc, DateTime};
use clap::{App, Arg};

#[derive(Debug, Clone)]
struct TransactionStats {
    count: usize,
    gas_price_total: U256,
    min_gas_price: U256,
    max_gas_price: U256,
    value_total: U256,
    min_value: U256,
    max_value: U256,
    start_time: DateTime<Utc>,
}

impl TransactionStats {
    fn new() -> Self {
        Self {
            count: 0,
            gas_price_total: U256::zero(),
            min_gas_price: U256::zero(),
            max_gas_price: U256::zero(),
            value_total: U256::zero(),
            min_value: U256::zero(),
            max_value: U256::zero(),
            start_time: Utc::now(),
        }
    }

    fn update(&mut self, tx: &Transaction) {
        self.count += 1;
        let gas_price = tx.gas_price.unwrap_or_default();
        self.gas_price_total += gas_price;
        
        if self.count == 1 || gas_price < self.min_gas_price {
            self.min_gas_price = gas_price;
        }
        
        if gas_price > self.max_gas_price {
            self.max_gas_price = gas_price;
        }

        let value = tx.value;
        self.value_total += value;
        
        if self.count == 1 || value < self.min_value {
            self.min_value = value;
        }
        
        if value > self.max_value {
            self.max_value = value;
        }
    }

    fn avg_gas_price(&self) -> U256 {
        if self.count == 0 {
            return U256::zero();
        }
        self.gas_price_total / self.count
    }

    fn transactions_per_second(&self) -> f64 {
        let duration = Utc::now() - self.start_time;
        let seconds = duration.num_milliseconds() as f64 / 1000.0;
        if seconds <= 0.0 {
            return 0.0;
        }
        self.count as f64 / seconds
    }
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    let matches = App::new("BSC Mempool Monitor")
        .version("1.0")
        .about("Monitors BSC mempool for new transactions")
        .arg(Arg::with_name("ws_url")
            .short("w")
            .long("ws")
            .value_name("WS_URL")
            .help("WebSocket URL of your BSC node")
            .default_value("ws://localhost:8576")
            .takes_value(true))
        .get_matches();

    let ws_url = matches.value_of("ws_url").unwrap();
    println!("Connecting to BSC node at {}", ws_url);

    // Connect to the node
    let ws = Ws::connect_with_reconnects(ws_url, 5).await?;
    let provider = Provider::new(ws);
    let provider = Arc::new(provider);

    // Initialize stats
    let stats = Arc::new(Mutex::new(TransactionStats::new()));
    let stats_clone = stats.clone();

    // Set up periodic reporting
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60));
        loop {
            interval.tick().await;
            let stats_snapshot = stats_clone.lock().await.clone();
            
            println!("\n---------- MEMPOOL STATISTICS ----------");
            println!("Transactions seen: {}", stats_snapshot.count);
            println!("Transactions per second: {:.2}", stats_snapshot.transactions_per_second());
            println!("Min gas price: {} gwei", wei_to_gwei(stats_snapshot.min_gas_price));
            println!("Max gas price: {} gwei", wei_to_gwei(stats_snapshot.max_gas_price));
            println!("Avg gas price: {} gwei", wei_to_gwei(stats_snapshot.avg_gas_price()));
            println!("Total value: {} BNB", wei_to_eth(stats_snapshot.value_total));
            println!("---------------------------------------\n");
        }
    });

    // Subscribe to pending transactions
    let mut stream = provider.subscribe_pending_txs().await?;
    println!("Successfully subscribed to pending transactions");

    // Process transactions
    while let Some(tx_hash) = stream.next().await {
        if let Ok(Some(tx)) = provider.get_transaction(tx_hash).await {
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
            stats_lock.update(&tx);
        }
    }

    Ok(())
}

// Helper function to convert wei to gwei
fn wei_to_gwei(wei: U256) -> f64 {
    let wei_str = wei.to_string();
    let wei_dec = wei_str.parse::<f64>().unwrap_or(0.0);
    wei_dec / 1_000_000_000.0
}

// Helper function to convert wei to ETH/BNB
fn wei_to_eth(wei: U256) -> f64 {
    let wei_str = wei.to_string();
    let wei_dec = wei_str.parse::<f64>().unwrap_or(0.0);
    wei_dec / 1_000_000_000_000_000_000.0
}