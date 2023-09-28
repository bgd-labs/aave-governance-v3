# Aave Governance v3

<img src="./docs/governance-v3-banner.jpg" alt="Aave Governance v3" width="75%" height="75%">

<br>

Aave Governance V3 is a smart contracts governance system enabling DAOs like Aave to create, vote and execute proposals in an efficient and scalable manner.

The architecture is multi-chain by design and powered by storage proofs, reducing significantly the cost of voting, while keeping the same levels of decentralization.

<br>

## Specifications

Extensive documentation about the architecture and design of the system can be found [HERE](./docs/overview.md).

Additional, more formal (but natural language) properties of the system can be found [HERE](./docs/properties.md)

<br>

## Setup instructions

All the information about setup of the project and deployments can be found [HERE](./docs/setup.md)

<br>

## Deployed Addresses

| Networks                                                                                                                                                                                                        | Governance                                                                                                            |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| <div style="display: flex; align-items: center;"><img src="./docs/networks/ethereum.svg" alt="Ethereum" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Ethereum</p></div>   | [0x9AEE0B04504CeF83A65AC3f0e838D0593BCb2BC7](https://etherscan.io/address/0x9AEE0B04504CeF83A65AC3f0e838D0593BCb2BC7) |

<br>

| Networks  | VotingMachine                                                                                                            |
|-----------|--------------------------------------------------------------------------------------------------------------------------|
| <div style="display: flex; align-items: center;"><img src="./docs/networks/ethereum.svg" alt="Ethereum" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Ethereum</p></div>  | [0x617332a777780F546261247F621051d0b98975Eb](https://etherscan.io/address/0x617332a777780F546261247F621051d0b98975Eb)    |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/polygon.svg" alt="Polygon" style="max-width: 25px%; margin-right: 5px;"><p style="text-align: center;">Polygon</p></div>   | [0xc8a2ADC4261c6b669CdFf69E717E77C9cFeB420d](https://polygonscan.com/address/0xc8a2ADC4261c6b669CdFf69E717E77C9cFeB420d) |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/avalanche.svg" alt="Avalanche" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Avalanche</p></div> | [0x9b6f5ef589A3DD08670Dd146C11C4Fb33E04494F](https://snowtrace.io/address/0x9b6f5ef589A3DD08670Dd146C11C4Fb33E04494F)    |

<br>

| Networks  | PayloadsController                                                                                                                | Executor Lvl1                                                                                                                      | Executor Lvl2                                                                                                          |
|-----------|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| <div style="display: flex; align-items: center;"><img src="./docs/networks/ethereum.svg" alt="Ethereum" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Ethereum</p></div>  |  [0x401B5D0294E23637c18fcc38b1Bca814CDa2637C](https://etherscan.io/address/0x401B5D0294E23637c18fcc38b1Bca814CDa2637C)            | [0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A](https://etherscan.io/address/0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A)              | [0x17Dd33Ed0e3dD2a80E37489B8A63063161BE6957](https://etherscan.io/address/0x17Dd33Ed0e3dD2a80E37489B8A63063161BE6957)  |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/polygon.svg" alt="Polygon" style="max-width: 25px%; margin-right: 5px;"><p style="text-align: center;">Polygon</p></div>   |  [0x401B5D0294E23637c18fcc38b1Bca814CDa2637C](https://polygonscan.com/address/0x401B5D0294E23637c18fcc38b1Bca814CDa2637C)         | [0xDf7d0e6454DB638881302729F5ba99936EaAB233](https://polygonscan.com/address/0xDf7d0e6454DB638881302729F5ba99936EaAB233)           | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/avalanche.svg" alt="Avalanche" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Avalanche</p></div> | [0x1140CB7CAfAcC745771C2Ea31e7B5C653c5d0B80](https://snowtrace.io/address/0x1140CB7CAfAcC745771C2Ea31e7B5C653c5d0B80)             | [0x3C06dce358add17aAf230f2234bCCC4afd50d090](https://snowtrace.io/address/0x3C06dce358add17aAf230f2234bCCC4afd50d090)              | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/arbitrum.svg" alt="Arbitrum" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Arbitrum</p></div>  |  [0x89644CA1bB8064760312AE4F03ea41b05dA3637C](https://arbiscan.io/address/0x89644CA1bB8064760312AE4F03ea41b05dA3637C)             | [0x89644CA1bB8064760312AE4F03ea41b05dA3637C](https://arbiscan.io/address/0x89644CA1bB8064760312AE4F03ea41b05dA3637C)               | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/optimism.svg" alt="Optimism" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Optimism</p></div>  | [0x0E1a3Af1f9cC76A62eD31eDedca291E63632e7c4](https://optimistic.etherscan.io/address/0x0E1a3Af1f9cC76A62eD31eDedca291E63632e7c4)  | [0x0E1a3Af1f9cC76A62eD31eDedca291E63632e7c4](https://optimistic.etherscan.io/address/0x0E1a3Af1f9cC76A62eD31eDedca291E63632e7c4)   | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/bsc.svg" alt="Binance" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Binance</p></div>   |[0xE5EF2Dd06755A97e975f7E282f828224F2C3e627](https://bscscan.com/address/0xE5EF2Dd06755A97e975f7E282f828224F2C3e627)               | [0x9390B1735def18560c509E2d0bc090E9d6BA257a](https://bscscan.com/address/0x9390B1735def18560c509E2d0bc090E9d6BA257a)               | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/base.svg" alt="Base" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Base</p></div>       |  [0x2DC219E716793fb4b21548C0f009Ba3Af753ab01](https://basescan.org/address/0x2DC219E716793fb4b21548C0f009Ba3Af753ab01)            | [0x9390B1735def18560c509E2d0bc090E9d6BA257a](https://basescan.org/address/0x9390B1735def18560c509E2d0bc090E9d6BA257a)              | -                                                                                                                      |
| <div style="display: flex; align-items: center;"><img src="./docs/networks/metis.svg" alt="Metis" style="max-width: 25px; margin-right: 5px;"><p style="text-align: center;">Metis</p></div>      | [0x2233F8A66A728FBa6E1dC95570B25360D07D5524](https://explorer.metis.io/address/0x2233F8A66A728FBa6E1dC95570B25360D07D5524)        | [0x6fD45D32375d5aDB8D76275A3932c740F03a8718](https://explorer.metis.io/address/0x6fD45D32375d5aDB8D76275A3932c740F03a8718)         | -                                                                                                                      |


<br>

## Security

The following security procedures have been applied:
- Extensive testing and internal review by the BGD Labs team.
  - [Tests suite](./tests).

- We have engaged [Emanuele Ricci](https://twitter.com/stermi) as external security partner in middle stages of the project, with outstanding results. This procedure was focused on non-biased modelling of the system in terms of flows and any kind of security problem and/or state inconsistency, keeping a tight feedback loop with the development team.


- Extensive properties checking (formal verification) procedure by [Certora](https://www.certora.com/), a security service provider of the Aave DAO.
  - [Report](./security/certora/Formal_Verification_Report_Aave_Governance_V3.md).
  - [Properties](./security/certora).

- Security review by [SigmaPrime](https://sigmaprime.io/), another security service provider of the Aave DAO.
  - [Reports](./security/sp).
  - [Test suite](https://github.com/sigp/aave-public-tests/tree/main/aave-governance-v3/tests).


**IMPORTANT**. The BUSL1.1 license of this repository allows for any usage of the software, if respecting the *Additional Use Grant* limitations, forbidding any use case damaging anyhow the Aave DAO's interests.


## License

Copyright © 2023, Aave DAO, represented by its governance smart contracts.

Created by [BGD Labs](https://bgdlabs.com/).

The default license of this repository is [BUSL1.1](./LICENSE), but all interfaces and the contents of the following folders are open source, MIT-licensed:
- [Data helpers](./src/contracts/dataHelpers/)
- [Misc libraries](./src/contracts/libraries/)
- [Voting libraries](./src/contracts/voting/libs/)

**IMPORTANT**. The BUSL1.1 license of this repository allows for any usage of the software, if respecting the *Additional Use Grant* limitations, forbidding any use case damaging anyhow the Aave DAO's interests.
