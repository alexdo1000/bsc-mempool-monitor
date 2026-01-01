use ethers::{
    prelude::*,
    types::{Address, U256},
    utils::parse_units,
};
use std::sync::Arc;
use tokio::sync::Mutex;
use std::collections::HashMap;
use std::time::Duration;

use crate::config::Config;

// Contract ABI
const FRONTRUNNER_ABI: &str = r#"[
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "targetToken",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amountIn",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "minProfit",
                "type": "uint256"
            },
            {
                "internalType": "address[]",
                "name": "path",
                "type": "address[]"
            }
        ],
        "name": "executeFrontrun",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]"#;

pub struct Frontrunner {
    contract: Contract<Provider<Ws>>,
    config: Config,
    // Track recent opportunities to avoid duplicates
    recent_opportunities: Arc<Mutex<Vec<(Address, U256)>>>,
    // Track gas costs
    gas_costs: Arc<Mutex<HashMap<Address, U256>>>,
    // Track current gas price
    current_gas_price: Arc<Mutex<U256>>,
}

impl Frontrunner {
    pub fn new(config: Config, provider: Arc<Provider<Ws>>) -> Self {
        let contract_address = config.frontrunner_contract.parse::<Address>().unwrap();
        let contract = Contract::new(contract_address, FRONTRUNNER_ABI, provider.clone());
        
        // Start gas price monitoring
        let current_gas_price = Arc::new(Mutex::new(U256::zero()));
        Self::start_gas_price_monitoring(provider.clone(), current_gas_price.clone());
        
        Self {
            contract,
            config,
            recent_opportunities: Arc::new(Mutex::new(Vec::new())),
            gas_costs: Arc::new(Mutex::new(HashMap::new())),
            current_gas_price,
        }
    }

    fn start_gas_price_monitoring(provider: Arc<Provider<Ws>>, current_gas_price: Arc<Mutex<U256>>) {
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(5));
            loop {
                interval.tick().await;
                if let Ok(gas_price) = provider.get_gas_price().await {
                    let mut price = current_gas_price.lock().await;
                    *price = gas_price;
                }
            }
        });
    }

    pub async fn execute_frontrun(
        &self,
        target_token: Address,
        amount_in: U256,
        min_profit: U256,
        path: Vec<Address>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Check if we've already tried this opportunity
        let mut recent = self.recent_opportunities.lock().await;
        if recent.contains(&(target_token, amount_in)) {
            return Ok(());
        }
        recent.push((target_token, amount_in));
        
        // Keep only last 100 opportunities
        if recent.len() > 100 {
            recent.remove(0);
        }
        drop(recent);

        // Get current gas price
        let gas_price = *self.current_gas_price.lock().await;
        if gas_price.is_zero() {
            return Err("Gas price not available".into());
        }

        // Calculate total costs (flash loan fee + gas buffer)
        let flash_loan_fee = (amount_in * U256::from(9)) / U256::from(10000);
        let gas_buffer = parse_units("0.01", "ether").unwrap();
        let total_costs = flash_loan_fee + gas_buffer;

        // Ensure profit covers costs
        if min_profit < total_costs {
            return Ok(());
        }

        // Execute the frontrun
        let tx = self.contract
            .method::<_, _, _, _, _>(
                "executeFrontrun",
                (target_token, amount_in, min_profit, path),
            )?
            .gas(500000) // Adjust gas limit as needed
            .gas_price(gas_price)
            .nonce(0) // You'll need to set the correct nonce
            .private(true); // Make it a private transaction

        // Send the transaction
        let pending_tx = tx.send().await?;
        println!("Frontrun transaction sent: {:?}", pending_tx.tx_hash());

        // Wait for confirmation
        let receipt = pending_tx.confirmations(1).await?;
        println!("Frontrun confirmed: {:?}", receipt);

        // Update gas costs
        if let Some(gas_used) = receipt.gas_used {
            let mut gas_costs = self.gas_costs.lock().await;
            gas_costs.insert(target_token, gas_used * gas_price);
        }

        Ok(())
    }

    pub async fn calculate_profit(
        &self,
        target_token: Address,
        amount_in: U256,
        path: Vec<Address>,
    ) -> Result<U256, Box<dyn std::error::Error>> {
        // Get current reserves from the DEX
        let pair = self.get_pair(path[0], path[1]).await?;
        let (reserve0, reserve1, _) = self.get_reserves(pair).await?;
        
        // Calculate expected output
        let expected_output = self.calculate_expected_output(
            amount_in,
            reserve0,
            reserve1,
            path[0] == self.get_token0(pair).await?,
        );
        
        // Calculate flash loan fee
        let flash_loan_fee = (amount_in * U256::from(9)) / U256::from(10000);
        
        // Get gas cost
        let gas_costs = self.gas_costs.lock().await;
        let gas_cost = gas_costs.get(&target_token).copied().unwrap_or_default();
        
        // Calculate total costs
        let total_costs = flash_loan_fee + gas_cost;
        
        // Calculate net profit
        Ok(expected_output - amount_in - total_costs)
    }

    // Helper methods for DEX interaction
    async fn get_pair(&self, token_a: Address, token_b: Address) -> Result<Address, Box<dyn std::error::Error>> {
        // Implement DEX pair lookup
        Ok(Address::zero()) // Replace with actual implementation
    }

    async fn get_reserves(&self, pair: Address) -> Result<(U256, U256, u32), Box<dyn std::error::Error>> {
        // Implement reserves lookup
        Ok((U256::zero(), U256::zero(), 0)) // Replace with actual implementation
    }

    async fn get_token0(&self, pair: Address) -> Result<Address, Box<dyn std::error::Error>> {
        // Implement token0 lookup
        Ok(Address::zero()) // Replace with actual implementation
    }

    fn calculate_expected_output(
        &self,
        amount_in: U256,
        reserve_in: U256,
        reserve_out: U256,
        is_token0: bool,
    ) -> U256 {
        let amount_in_with_fee = amount_in * U256::from(9975);
        let numerator = amount_in_with_fee * (if is_token0 { reserve_out } else { reserve_in });
        let denominator = (if is_token0 { reserve_in } else { reserve_out }) * U256::from(10000) + amount_in_with_fee;
        numerator / denominator
    }
} 