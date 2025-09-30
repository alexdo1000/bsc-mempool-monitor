// scripts/deploy.js
async function main() {
    // Get the contract factory
    const FrontrunnerContract = await ethers.getContractFactory("FrontrunnerContract");
    
    // Deploy the contract
    console.log("Deploying FrontrunnerContract...");
    const frontrunner = await FrontrunnerContract.deploy();
    
    // Wait for deployment to finish
    await frontrunner.deployed();
    console.log("FrontrunnerContract deployed to:", frontrunner.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });