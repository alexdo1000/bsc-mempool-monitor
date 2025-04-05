use ethers::types::U256;

/// Convert wei to gwei (1 gwei = 1,000,000,000 wei)
pub fn wei_to_gwei(wei: U256) -> f64 {
    let wei_str = wei.to_string();
    let wei_dec = wei_str.parse::<f64>().unwrap_or(0.0);
    wei_dec / 1_000_000_000.0
}

/// Convert wei to ETH/BNB (1 ETH/BNB = 1,000,000,000,000,000,000 wei)
pub fn wei_to_eth(wei: U256) -> f64 {
    let wei_str = wei.to_string();
    let wei_dec = wei_str.parse::<f64>().unwrap_or(0.0);
    wei_dec / 1_000_000_000_000_000_000.0
} 