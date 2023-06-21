const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    
    data = await ethers.getContractFactory("Echo");
    echo = await data.deploy();
    txDeployed = await echo.deployed();
    console.log("Echo Address: ", echo.address)

    data = await ethers.getContractFactory("VeArtProxy");
    veArtProxy = await data.deploy();
    txDeployed = await veArtProxy.deployed();
    console.log("veArtProxy Address: ", veArtProxy.address)

    data = await ethers.getContractFactory("VotingEscrow");
    veEcho = await data.deploy(echo.address, veArtProxy.address);
    txDeployed = await veEcho.deployed();
    console.log("veEcho Address: ", veEcho.address)

    data = await ethers.getContractFactory("RewardsDistributor");
    RewardsDistributor = await data.deploy(veEcho.address);
    txDeployed = await RewardsDistributor.deployed();
    console.log("RewardsDistributor Address: ", RewardsDistributor.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
