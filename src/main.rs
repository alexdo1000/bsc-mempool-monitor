use ethers::{
    prelude::*,
    providers::{Middleware, Provider, Ws},
    types::{Transaction, H256, U256},
};
use futures::StreamExt;
use std::{collections::HashMap, sync::Arc, time::{Duration, Instant}};
use tokio::{sync::Mutex, time};
use clap::{App, Arg};
use chrono::{Utc, DateTime};
use std::str::FromStr;

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
            min_gas_price: U256::max_value(),
            max_gas_price: U256::zero(),
            value_total: U256::zero(),
            min_value: U256::max_value(),
            max_value: U256::zero(),
            start_time: Utc::now(),
        }
    }

    fn update(&mut self, tx: &Transaction) {
        self.count += 1;

        // Handle gas price
        let gas_price = tx.gas_price.unwrap_or_default();
        self.gas_price_total += gas_price;
        if gas_price < self.min_gas_price {
            self.min_gas_price = gas_price;
        }
        if gas_price > self.max_gas_price {
            self.max_gas_price = gas_price;
        }

        // Handle value
        let value = tx.value;
        self.value_total += value;
        if value < self.min_value {
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

// Define interesting contract addresses to monitor
// You can replace these with addresses you're interested in
const PANCAKESWAP_ROUTER_V2: &str = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const BISWAP_ROUTER: &str = "0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8";

#[tokio::main]
async fn main() -> eyre::Result<()> {
    // Parse command line arguments
    let matches = App::new("BSC Mempool Monitor")
        .version("1.0")
        .about("Monitors BSC mempool for new transactions")
        .arg(Arg::with_name("ws_url")
            .short('w')
            .long("ws")
            .value_name("WS_URL")
            .help("WebSocket URL of your BSC node")
            .default_value("ws://localhost:8546")
            .takes_value(true))
        .arg(Arg::with_name("min_value")
            .short('v')
            .long("min-value")
            .value_name("ETH_VALUE")
            .help("Minimum transaction value to log (in BNB)")
            .default_value("0.1")
            .takes_value(true))
        .arg(Arg::with_name("report_interval")
            .short('r')
            .long("report")
            .value_name("SECONDS")
            .help("Interval in seconds for reporting statistics")
            .default_value("60")
            .takes_value(true))
        .get_matches();

    // Get configuration values
    let ws_url = matches.value_of("ws_url").unwrap();
    let min_value = matches.value_of("min_value").unwrap()
        .parse::<f64>().unwrap();
    let min_value_wei = U256::from_dec_str(
        &(min_value * 1e18).to_string().split('.').next().unwrap()
    ).unwrap();
    let report_interval = matches.value_of("report_interval").unwrap()
        .parse::<u64>().unwrap();

    println!("Connecting to BSC node at {}", ws_url);
    println!("Monitoring for transactions with minimum value of {} BNB", min_value);
    println!("Will report statistics every {} seconds", report_interval);

    // Connect to the node
    let ws = Ws::connect(ws_url).await?;
    let provider = Provider::new(ws);
    let provider = Arc::new(provider);

    // Initialize stats
    let stats = Arc::new(Mutex::new(TransactionStats::new()));
    let stats_clone = stats.clone();

    // Set up periodic reporting
    tokio::spawn(async move {
        let mut interval = time::interval(Duration::from_secs(report_interval));
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

    // Set up interesting address tracking
    let router_addresses = vec![
        PANCAKESWAP_ROUTER_V2.parse::<Address>().unwrap(),
        BISWAP_ROUTER.parse::<Address>().unwrap(),
    ];

    // Subscribe to pending transactions
    let mut stream = provider.subscribe_pending_txs().await?;
    println!("Successfully subscribed to pending transactions");
    
    // Set up a counter to rate limit console logging
    let mut tx_counter = 0;
    let log_every_n = 100; // Only log every Nth transaction to prevent console flood

    // Set up tracking for high-value transactions
    let mut high_value_txs = HashMap::new();
    let mut last_cleanup = Instant::now();
    let cleanup_interval = Duration::from_secs(300); // Clean up every 5 minutes

    // Process transactions as they come in
    while let Some(tx_hash) = stream.next().await {
        // Get full transaction details
        if let Ok(Some(tx)) = provider.get_transaction(tx_hash).await {
            // Update stats
            let mut stats_lock = stats.lock().await;
            stats_lock.update(&tx);
            
            // Determine if this transaction is interesting
            let is_high_value = tx.value >= min_value_wei;
            let is_router_interaction = router_addresses.contains(&tx.to.unwrap_or_default());
            
            // Track high-value transactions
            if is_high_value {
                high_value_txs.insert(tx_hash, tx.clone());
            }
            
            // Log interesting transactions
            if is_high_value || is_router_interaction || tx_counter % log_every_n == 0 {
                println!("[{}] New tx: {:?}", Utc::now().format("%H:%M:%S"), tx_hash);
                
                if is_high_value {
                    println!("  HIGH VALUE: {} BNB", wei_to_eth(tx.value));
                }
                
                if is_router_interaction {
                    println!("  DEX INTERACTION: {:?}", tx.to.unwrap());
                    if tx.input.len() >= 4 {
                        // First 4 bytes of call data are the function selector
                        let selector = hex::encode(&tx.input[..4]);
                        println!("  Function selector: 0x{}", selector);
                    }
                }
                
                println!("  From: {:?}", tx.from);
                println!("  To: {:?}", tx.to);
                println!("  Value: {} BNB", wei_to_eth(tx.value));
                println!("  Gas price: {} gwei", wei_to_gwei(tx.gas_price.unwrap_or_default()));
                println!("  Gas: {}", tx.gas);
                println!("  Nonce: {}", tx.nonce);
                println!("");
            }
            
            tx_counter += 1;
            
            // Clean up old high-value txs
            if last_cleanup.elapsed() > cleanup_interval {
                high_value_txs.clear();
                last_cleanup = Instant::now();
            }
        }
    }

    Ok(())
}

// Helper function to convert wei to gwei
fn wei_to_gwei(wei: U256) -> f64 {
    let wei_dec = wei.as_u128() as f64;
    wei_dec / 1_000_000_000.0
}

// Helper function to convert wei to ETH/BNB
fn wei_to_eth(wei: U256) -> f64 {
    let wei_dec = wei.as_u128() as f64;
    wei_dec / 1_000_000_000_000_000_000.0
}