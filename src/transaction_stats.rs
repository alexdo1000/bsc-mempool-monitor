use ethers::types::{Transaction, U256};
use chrono::{Utc, DateTime};
use std::sync::Arc;
use tokio::sync::Mutex;

pub type SharedStats = Arc<Mutex<TransactionStats>>;

#[derive(Debug, Clone)]
pub struct TransactionStats {
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
    pub fn new() -> Self {
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

    pub fn update(&mut self, tx: &Transaction) {
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

    pub fn count(&self) -> usize {
        self.count
    }

    pub fn min_gas_price(&self) -> U256 {
        self.min_gas_price
    }

    pub fn max_gas_price(&self) -> U256 {
        self.max_gas_price
    }

    pub fn avg_gas_price(&self) -> U256 {
        if self.count == 0 {
            return U256::zero();
        }
        self.gas_price_total / self.count
    }

    pub fn value_total(&self) -> U256 {
        self.value_total
    }

    pub fn transactions_per_second(&self) -> f64 {
        let duration = Utc::now() - self.start_time;
        let seconds = duration.num_milliseconds() as f64 / 1000.0;
        if seconds <= 0.0 {
            return 0.0;
        }
        self.count as f64 / seconds
    }
} 