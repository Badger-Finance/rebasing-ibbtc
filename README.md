# ibBTC Rebasing Wrapper
The issue: ibBTC value vs WBTC will change over time within the curve pool. StableSwap invariant means you only get low or even reasonable slippage when the balances of both coins are very close. The variance between value will perpetually increase.

Introducing, **wibBTC**

## Facts
* totalShares is the number of ibBTC tokens in the wrapper
* totalSupply is PPFS * totalShares
* balanceOf(user) = userShares * PPFS

When a user deposits ibBTC into the wrapper, they get the same number of shares as ibBTC tokens they deposit. Their balance is then dynamic based on the share amount, and PPFS.

PPFS is set by an oracle. 

When a user withdraws from the wrapper to return to iBBTC, do they withdraw in iBBTC tokens or shares?

Does ribBTC exist on ETH? It presumably will need representations on all chains we have a curve pool on.

## Risks
* We introduce a trusted oracle. If it goes haywire and reports bad data, the pool could have 1000x the ribBTC, or 1/1000 the riBBTC, compared to iBBTC. What will happen in this case?

* As with any rebaser we introduce precision loss / _dust_. How does this simple rebasing calculation work as compared with Ampleforth?

# UX
Users need to convert ibBTC to ribBTC before depositing into curve pool. They then need to deposit values into the curve pool denominated in balances rather than shares.

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
