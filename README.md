> ⚠️ These contracts are in a draft state and unaudited. They shouldn't be used in production. 

# ibBTC Rebasing Wrapper
When ibBTC is placed in a curve BTC metapool, the value of ibBTC tokens will deviate relative to the value of the Curve LP tokens. This is due to the yearn vault-like price per share mechanic of ibBTC. StableSwap invariant means you only get low or even reasonable slippage when the balances of both coins are very close. The variance between value may perpetually increase as ibBTC increases in value.

While we develop a custom pool, this wrapper allows for the value of each ibBTC coin in the pool to remain equal to the underlying tokenized BTC collateral so that the metapool can function as intended.

Introducing, **wibBTC**.

## How it works
* Users deposit ibBTC into the contract and are minted shares at 1-1 to the token value deposited. This value is tracked in `sharesOf(account)`
* `totalShares()` is the number of ibBTC tokens in the wrapper
* `totalSupply()` is ibBTC pricePerShare * totalShares. The total supply increases relative to the number of shares as the pricePerShare increases. This means 1 unit of wibBTC = 1 tokenized BTC in value.
    * ibBTC pricePerShare is read directly from the ibBTC Core contract on Ethereum, and is read from an oracle on other chains.
* `balanceOf(account)` = sharesOf(account) * pricePerShare. As per typical rebasing tokens, each accounts' balance scales

## Admin Functionality
* Governance 
* Governance can set a new pendingGovernance address, which must `acceptPendingGovernance()`


## Risks
* We introduce a trusted oracle on non-ETH chains. If it goes haywire and reports bad data, the pool could have 1000x the ribBTC, or 1/1000 the riBBTC, compared to iBBTC. What will happen in this case?
* On Ethereum, if there's a pricePerShare bug in the ibBTC Core, what new considerations are introduced by the curve pool?
* As with any rebaser we introduce precision loss / _dust_. Are there any concerns here?

* What sanity checks to have on oracle?
    * Ensure oracle value never changes by an extreme amount?
    * Ensure oracle never goes down?
    * What should happen IF ibBTC is legitimately exploited... Is it better to keep this value at the new value or the pre-exploit expected value?

## Contracts
A live instance of the wrapper can be found here (pending). It's using a proxy + logic split for upgradeability. 
There is a test curve pool vs sbtc on Ethereum (pending), and a test pool vs ren on Polygon.

# UX Considerations
Users need to convert ibBTC to wibBTC before depositing into curve pool. They then need to deposit values into the curve pool denominated in balances rather than shares.

# CodeArena Spec
4. How many external calls? 
    * One, to ibBTC Core contract on ETH mainnet, and to a defined oracle address on other chains.
5. Does it use an oracle?
    * Yes, this is a custom ibBTC pricePerShare oracle in development by chainlink.
6. Does the token conform to the ERC20 standard?
    * Yes, with custom minting & burning functions. It's based on the OZ ERC20Upgradeable contract.
12. Is it multichain?
    * Yes in the sense that it reads oracle data from other chains when not used on ETH mainnet.
13. Does it use a sidechain?
    * It will exist on sidechains as per above
13a. If yes, is the sidechain evm-compatible?
    * Yes, it will only be present on EVM sidechains

# Basic Sample Hardhat Project
This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
