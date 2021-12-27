const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers

const { impersonateAccount, constants } = require('./utils');

const ibbtc_address = "0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F";
const core_address = "0x2A8facc9D49fBc3ecFf569847833C380A13418a8";
const ibBTC_whale = "0x1d5e65a087ebc3d03a294412e46ce5d6882969f4"; // Has 28.799212116895151324 ibBTC

describe("WrappedIbbtcEth", function () {
  let governance;
  let user;
  let ibBTC;
  let wibBTC;

  // Needs Infura account with access to Archive Node:
  // before(async function() {
  //     // Running from specific block to ensure whale's balance
  //     await network.provider.request({
  //       method: "hardhat_reset",
  //       params: [{
  //           forking: {
  //               jsonRpcUrl: new ethers.providers.InfuraProvider('mainnet', process.env.INFURA_PROJECT_ID).connection.url,
  //               blockNumber: 13495247 // having a consistent block number speeds up the tests across runs
  //           }
  //       }]
  //   });
  // })

  beforeEach(async function () {
    // Get actors
    [governance, user, ...addrs] = await ethers.getSigners();

    // Get the ibBTC contract
    ibBTC = await ethers.getContractAt('ERC20Upgradeable', ibbtc_address)
    // Get the ContractFactory and deploy the wrapper
    const WrappedIbbtcEth = await ethers.getContractFactory("WrappedIbbtcEth");
    wibBTC = await WrappedIbbtcEth.deploy();
    await wibBTC.deployed();
    await wibBTC.initialize(governance.address, ibbtc_address, core_address);
  });
  
  it("Contract initializes properly", async function () {
    expect(await wibBTC.governance()).to.equal(governance.address);
    expect(await wibBTC.ibbtc()).to.equal(ibbtc_address);
    expect(await wibBTC.core()).to.equal(core_address);
  });

  it("Mints and Redeems properly", async function () {
    await impersonateAccount(ibBTC_whale);
    signer = ethers.provider.getSigner(ibBTC_whale)
    const whale_balance = await ibBTC.balanceOf(ibBTC_whale);

    const amount = constants._1e18;
    expect(whale_balance.gte(BigNumber.from(amount)));

    // wibBTC MINT
    expect((await wibBTC.totalSupply()).eq(BigNumber.from(0)));

    await ibBTC.connect(signer).approve(wibBTC.address, amount);
    await wibBTC.connect(signer).mint(amount);

    expect((await ibBTC.balanceOf(ibBTC_whale)).eq(whale_balance.sub(amount)));
    expect((await wibBTC.balanceOf(ibBTC_whale)).eq(amount));
    expect((await wibBTC.sharesOf(ibBTC_whale)).eq(amount));
    expect((await wibBTC.totalSupply()).eq(amount));

    // wibBTC Transfer
    await wibBTC.connect(signer).transfer(user.address, amount.div(2));

    expect((await wibBTC.balanceOf(ibBTC_whale)).eq(amount.div(2)));
    expect((await wibBTC.sharesOf(ibBTC_whale)).eq(amount.div(2)));
    expect((await wibBTC.balanceOf(user.address)).eq(amount.div(2)));
    expect((await wibBTC.sharesOf(user.address)).eq(amount.div(2)));
    expect((await wibBTC.totalSupply()).eq(amount));

    // wibBTC BURN
    await wibBTC.connect(signer).burn(amount.div(2));

    expect((await ibBTC.balanceOf(ibBTC_whale)).eq(whale_balance.add(amount.div(2))));
    expect((await wibBTC.balanceOf(ibBTC_whale)).eq(0));
    expect((await wibBTC.totalSupply()).eq(amount.div(2)));

    // wibBTC user BURN
    await wibBTC.connect(user).burn(amount.div(2));

    expect((await ibBTC.balanceOf(user.address)).eq(amount.div(2)));
    expect((await wibBTC.balanceOf(user.address)).eq(0));
    expect((await wibBTC.totalSupply()).eq(0));
  });
});
