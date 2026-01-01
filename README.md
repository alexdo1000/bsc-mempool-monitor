# BSC Mempool Monitor & Full Node Implementation

A high-performance, production-ready system for monitoring the Binance Smart Chain (BSC) mempool in real-time, built with Rust and Erigon. This project demonstrates expertise in blockchain infrastructure, concurrent systems programming, and low-latency transaction processing.

## 🚀 Overview

This repository contains a complete implementation of:

- **Full BSC Node**: Self-hosted Erigon full node with optimized configuration for BSC mainnet and testnet
- **Real-time Mempool Monitor**: High-throughput transaction monitoring system with WebSocket subscriptions
- **MEV Detection**: Advanced pattern recognition for identifying arbitrage opportunities and MEV bot activity
- **Performance Optimized**: Multi-threaded architecture with worker pools and batch processing

## 💼 Technical Skills Demonstrated

This project showcases expertise in:

- **Systems Programming**: Low-level Rust development with focus on performance and memory safety
- **Concurrent Systems**: Multi-threaded architecture with worker pools, channels, and async/await patterns
- **Blockchain Infrastructure**: Full node deployment, configuration, and optimization for production use
- **Real-time Systems**: WebSocket-based event streaming with sub-100ms latency requirements
- **Performance Engineering**: Throughput optimization, batch processing, and resource management
- **Network Programming**: WebSocket protocol implementation, connection management, and error handling
- **Production Operations**: Node management, monitoring, logging, and deployment automation
- **Problem Solving**: MEV detection algorithms, pattern recognition, and transaction analysis

## 🏗️ Architecture

### Full Node (Erigon)

The full node implementation uses [Erigon](https://github.com/ledgerwatch/erigon), a high-performance Ethereum client optimized for resource efficiency. The configuration includes:

- **Pruned Mode**: Minimal storage footprint with 300GB database limit
- **Optimized Batch Processing**: 2GB batch size for efficient state management
- **High Concurrency**: Configured for 4 concurrent RPC batch operations
- **Comprehensive API Access**: Full access to `eth`, `net`, `web3`, `txpool`, `debug`, and `trace` APIs
- **WebSocket Support**: Real-time event streaming for mempool monitoring

### Mempool Monitor (Rust)

The monitoring system is built with Rust for maximum performance and safety:

- **Async/Await Architecture**: Built on Tokio for high-concurrency async operations
- **WebSocket Subscriptions**: Real-time pending transaction stream from Erigon
- **Worker Pool Pattern**: Multi-threaded processing with configurable worker count (2x CPU cores)
- **Batch Processing**: Efficient transaction batching with 5,000 transaction buffer per worker
- **Statistics Tracking**: Real-time metrics including TPS, gas prices, and transaction values
- **Pattern Detection**: Identifies DEX swaps, MEV bot activity, and high-value transactions

## 📊 Key Features

### Performance
- **High Throughput**: Processes thousands of transactions per second
- **Low Latency**: Sub-second transaction detection and analysis
- **Resource Efficient**: Optimized memory usage with bounded buffers
- **Fault Tolerant**: Automatic reconnection with exponential backoff

### Monitoring Capabilities
- Real-time transaction stream monitoring
- Gas price analytics (min, max, average)
- Transaction value tracking
- DEX router interaction detection (PancakeSwap V1/V2, ApeSwap)
- MEV bot identification
- Sandwich attack pattern detection

### Technical Highlights
- **Type Safety**: Leverages Rust's type system for memory safety
- **Concurrent Processing**: Rayon and Tokio for parallel execution
- **Error Handling**: Comprehensive error handling with `eyre` for better diagnostics
- **Configuration**: CLI-based configuration with sensible defaults

## 🛠️ Technology Stack

- **Rust**: Systems programming language for performance and safety
- **Erigon**: High-performance Ethereum client
- **Tokio**: Async runtime for Rust
- **Ethers.rs**: Ethereum library for Rust
- **WebSocket**: Real-time bidirectional communication
- **BSC Network**: Binance Smart Chain mainnet and testnet support

## 📁 Project Structure

```
.
├── fullnode/              # Erigon full node configuration
│   ├── gethConfigs/      # Node configuration files
│   │   ├── mainnet/      # Mainnet configuration
│   │   └── testnet/      # Testnet configuration
│   └── *.sh              # Node management scripts
├── rust/                 # Mempool monitor implementation
│   ├── src/
│   │   ├── main.rs       # Application entry point
│   │   ├── mempool_monitor.rs  # Core monitoring logic
│   │   ├── transaction_stats.rs # Statistics tracking
│   │   ├── frontrunner/  # MEV detection and execution
│   │   └── config.rs     # Configuration management
│   └── Cargo.toml        # Rust dependencies
└── contracts/            # Smart contracts (if applicable)
```

## 🚦 Getting Started

### Prerequisites

- Rust 1.70+ (for mempool monitor)
- Erigon binary (for full node)
- Sufficient disk space (300GB+ recommended for pruned node)
- High-bandwidth internet connection

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bsc-mempool-monitor
   ```

2. **Install dependencies**
   ```bash
   ./installDependencies.sh
   ```

3. **Build the Rust application**
   ```bash
   cd rust
   cargo build --release
   ```

### Running the Full Node

1. **Start Erigon node** (mainnet)
   ```bash
   cd fullnode/gethConfigs
   ./startErigon.sh
   ```

   The node will sync with the BSC network. Initial sync may take several hours.

2. **Verify node status**
   ```bash
   ./nodeSyncStatus.sh
   ```

### Running the Mempool Monitor

1. **Start the monitor** (connects to local Erigon node)
   ```bash
   cd rust
   cargo run --release -- --ws-url ws://localhost:8576
   ```

2. **Custom configuration**
   ```bash
   cargo run --release -- \
     --ws-url ws://localhost:8576 \
     --report-interval 10 \
     --min-profit-threshold 0.1
   ```

## 📈 Performance Metrics

The system is designed to handle high transaction volumes:

- **Transaction Processing**: 5,000+ transactions/second per worker
- **Latency**: <100ms from transaction broadcast to detection
- **Memory Usage**: ~500MB per worker (configurable)
- **CPU Usage**: Efficiently utilizes all available cores

## 🔧 Configuration

### Erigon Configuration

Key configuration files:
- `fullnode/gethConfigs/mainnet/erigon-config.toml`: Mainnet node settings
- `fullnode/gethConfigs/mainnet/config.toml`: Additional node parameters

### Mempool Monitor Configuration

Command-line arguments:
- `--ws-url`: WebSocket endpoint (default: `ws://localhost:8576`)
- `--report-interval`: Statistics report interval in seconds (default: 5)
- `--min-profit-threshold`: Minimum profit threshold for frontrunning (default: 0.1 BNB)
- `--frontrunner-contract`: Frontrunner contract address (optional)

## 🧪 Testing

Test the system on BSC testnet before using on mainnet:

```bash
cd fullnode/gethConfigs
./startTestnode.sh
```

Then run the monitor against the testnet node.

## 📝 Development Notes

### Design Decisions

1. **Rust for Performance**: Chosen for zero-cost abstractions and memory safety
2. **Erigon over Geth**: Better resource efficiency and faster sync times
3. **Worker Pool Pattern**: Ensures even distribution of transaction processing
4. **WebSocket Subscriptions**: Lower latency than polling-based approaches
5. **Batch Processing**: Reduces overhead and improves throughput

### Future Enhancements

- [ ] Database persistence for transaction history
- [ ] REST API for querying statistics
- [ ] Web dashboard for real-time visualization
- [ ] Advanced MEV strategy implementation
- [ ] Support for additional DEX protocols

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 📄 License

[Specify your license here]

## 🔗 Resources

- [Erigon Documentation](https://github.com/ledgerwatch/erigon)
- [BSC Documentation](https://docs.binance.org/smart-chain/developer/rpc.html)
- [Ethers.rs Documentation](https://ethers.rs/)

---

**Built with ❤️ for high-performance blockchain infrastructure**

