const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const web3 = require('web3');
const fs = require('fs');

describe("TixToken with ServiceDeployer", function () {
  let owner, addr1, addr2, tixToken, serviceDeployer;

  async function deployFixture() {
    const initialSupply = BigInt(1000) * BigInt(10 ** 18);
    [owner, addr1, addr2] = await ethers.getSigners();

    const TixToken = await ethers.getContractFactory("TixToken");
    const tixToken = await TixToken.deploy(initialSupply);
    const ServiceDeployer = await ethers.getContractFactory("ServiceDeployer");
    const serviceDeployer = await ServiceDeployer.deploy(tixToken.target);

    const serviceWorkerRole = await tixToken.SERVICE_WORKER();
    await tixToken.grantRole(serviceWorkerRole, serviceDeployer.target);   

    return { tixToken, serviceDeployer };
}


  it("Should set the right initial supply", async function () {
    const { tixToken } = await loadFixture(deployFixture);
    const initialSupply = BigInt(1000) * BigInt(10 ** 18);

    expect(await tixToken.totalSupply()).to.equal(initialSupply);
  });

  it("Should revert when non-owner tries to set registration fee", async function () {
    const { tixToken } = await loadFixture(deployFixture);
    const [_, nonOwner] = await ethers.getSigners();

    await expect(tixToken.connect(nonOwner).setRegistrationFee(100)).to.be.revertedWith("TixToken: must have balancer role to update fees");
  });

  // Check if registration fee is set correctly
  it("Should set the correct registration fee", async function () {    
    const { tixToken } = await loadFixture(deployFixture);
    await tixToken.setRegistrationFee(BigInt(10) * BigInt(10 ** 18));
    expect(await tixToken._registrationFee()).to.equal(BigInt(10) * BigInt(10 ** 18));
  });
  
  it("Should deduct the registration fee when registering a service", async function () {
    const { tixToken, serviceDeployer } = await loadFixture(deployFixture);
    await tixToken.setRegistrationFee(BigInt(10) * BigInt(10 ** 18));
    await tixToken.transfer(addr1.address, BigInt(15) * BigInt(10 ** 18));

    // Load bytecode from file
    const bytecode = "0x" + fs.readFileSync('./bin/Audit/RentalWorkflow.bin', 'utf8');

    // Mock data for service registration
    const name = "TestService";
    const spec = "TestSpec";

    await serviceDeployer.connect(addr1).deploy(name, spec, bytecode);

    const finalBalance = await tixToken.balanceOf(addr1.address);
    expect(finalBalance).to.equal(BigInt(5) * BigInt(10 ** 18));
  });

  // Check if registration fails when not enough balance
  it("Should revert if not enough TIX to register a service", async function () {
    const { tixToken } = await loadFixture(deployFixture);
    await tixToken.setRegistrationFee(BigInt(10000) * BigInt(10 ** 18)); // Setting a high fee

    const name = "TestService";
    const spec = "TestSpec";

    await expect(tixToken.registerService(name, spec, addr1.address, owner.address)).to.be.revertedWith("TixToken: Not enough TIX to register a service");
  });

  it("Should register multiple services", async function () {
    const { tixToken } = await loadFixture(deployFixture);
    const names = ["Service1", "Service2"].map(name => web3.utils.keccak256(name));
    const services = [
      { destination: addr1.address, owner: owner.address, spec: "Spec1" },
      { destination: addr2.address, owner: owner.address, spec: "Spec2" }
    ];

    await tixToken.registerServices(names, services);

    for (let i = 0; i < names.length; i++) {
      const service = await tixToken.repository(names[i]);
      expect(service.destination).to.equal(services[i].destination);
      expect(service.owner).to.equal(services[i].owner);
      expect(service.spec).to.equal(services[i].spec);
    }
  });
});
