require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: "0.8.19",
  networks: {
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: ["YOUR_PRIVATE_KEY_HERE"]
    }
  },
  etherscan: {
    // BSC API key from BscScan
    apiKey: "YOUR_BSCSCAN_API_KEY"
  }
};