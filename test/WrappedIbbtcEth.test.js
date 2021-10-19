const { expect } = require("chai");
const { ethers } = require("hardhat");

const ibbtc_address = "0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F";
const core_address = "0x2A8facc9D49fBc3ecFf569847833C380A13418a8";

describe("WrappedIbbtcEth", function () {
  let governance;
  let user;
  let ibBTC;
  let wibBTC;

  beforeEach(async function () {
    // Get actors
    [governance, user, ...addrs] = await ethers.getSigners();

    // Get the ibBTC contract
    ibBTC = await ethers.getContractAt('ERC20Upgradeable', ibbtc_address)
    // Get the ContractFactory and deploy the wrapper
    const WrappedIbbtcEth = await ethers.getContractFactory("WrappedIbbtcEth");
    wibBTC = await WrappedIbbtcEth.deploy();
    await wibBTC.deployed();
  });
  
  it("Contract initializes properly", async function () {
    await wibBTC.initialize(governance.address, ibbtc_address, core_address);
    expect(await wibBTC.governance()).to.equal(governance.address);
    expect(await wibBTC.ibbtc()).to.equal(ibbtc_address);
    expect(await wibBTC.core()).to.equal(core_address);
  });
});
