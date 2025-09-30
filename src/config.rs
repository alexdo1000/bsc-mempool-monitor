use clap::Parser;
use std::time::Duration;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Config {
    /// WebSocket URL of the BSC node
    #[arg(short = 'w', long, default_value = "ws://localhost:8576")]
    pub ws_url: String,

    /// Report interval in seconds
    #[arg(short = 'i', long, default_value = "5")]
    pub report_interval: u64,

    /// Frontrunner contract address
    #[arg(short = 'f', long)]
    pub frontrunner_contract: String,

    /// Minimum profit threshold in BNB
    #[arg(short = 'p', long, default_value = "0.1")]
    pub min_profit_threshold: f64,
}

impl Config {
    pub fn report_interval(&self) -> Duration {
        Duration::from_secs(self.report_interval)
    }
} 