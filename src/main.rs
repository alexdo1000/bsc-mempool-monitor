use bsc_mempool_monitor::{Config, MempoolMonitor};

#[tokio::main]
async fn main() -> eyre::Result<()> {
    // Get configuration from command line arguments
    let config = Config::from_args();

    // Create and start the mempool monitor
    let mut monitor = MempoolMonitor::new(config);
    monitor.start().await?;

    Ok(())
}