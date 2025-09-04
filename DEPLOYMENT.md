# Deployment of the Aave Governance V3 Contracts

On this document we will specify the different steps needed to deploy the different parts of the Aave Governance system, consisting on:

// TODO: add links to sections
- Governance
- Voting
- Execution

## Setup

There are a few things to take into account that will need to be updated / modified for deployments on different networks.

- *.env*: copy [.env.example](./.env.example) into `.env` file, and fill it. the private key is only need if you want to deploy with it. If not you only need to fill `MNEMONIC_INDEX` and `LEDGER_SENDER` (specified later on how to choose between the two ways of deployment)
- *[foundry.toml](./foundry.toml)*: when adding a new network, you should also add the respective definitions (rpc_endpoints and etherscan). Under the etherscan section you should only add the network configuration if its not supported by etherscan. If there is a network that needs special configuration, add it there also, under the network profile.
- *scripts*: These can be found in the folder [scripts](./scripts/). Here you will find the deployment scripts needed for the different parts of the system.
If you are adding a new network, you will first need to double check that the nework is added in [Solidity Utils](https://github.com/bgd-labs/solidity-utils/blob/main/src/contracts/utils/ChainHelpers.sol) repository, add the network path in [GovBaseScript](), and then add a new network script in [InitialDeployment.s.sol](). When using the scripts for the deployments, they will get the necessary addresses from the generated json files under [deployments](./deployments/) folder, so it is necessary to follow the strict deployment order, that will be specified later. After deployment, the scripts save the new deployed addresses in the mentioned json files.
- *deployments*: The [deployments](./deployments/) folder contains the deployed addresses for every network. Its important to take into account that the json files will be modified with the script execution or simulation, so if there is a simulation but execution fails, the addresses will be modified. Also take into account that for some of the Governance smart contract deployments, there is a need to have [aDI](https://github.com/aave-dao/adi-deploy/tree/main/deployments/cc/mainnet) addresses. When deploying for a new network you need to add the addresses json from there under the directory [/deployments/cc/mainnet/](./deployments/cc/mainnet/) as its the directory used in the scripts to search for addresses. Keep in mind that these need to be up to date, or the Governance contracts you deploy will not be correctly connected. 
- *Makefile*: This can be found [here](./Makefile). I has the commands to be able to deploy each smart contract for the selected network. If you need to deploy any of the smart contracts to a new 
network, (after you have added the necessary network scripts), you just need to change the network name in the necessary command and execute it.
You can deploy using a private key or a ledger by adding `LEDGER=true` to the execution command. If you want to deploy into a mainnet network, you would need to add: `PROD=true`

You can see here an example of executing the first command that you need that will generate the specified network addresses json:

```
deploy-initial:
	$(call deploy_fn,InitialDeployments,ethereum polygon avalanche arbitrum optimism metis base binance gnosis)
```
In this case you would need to only have the network that you want to deploy on. If you leave multiple networks in the command, it will deploy on all of them sequentially.

Execution command would look like this: `make deploy-initial PROD=true LEDGER=true`

### Notes

## Governance Network

The governance network is the central hub where Aave Governance is managed (more [here](TODO: add link to docs)). The contracts needed for it to work are:
- [Governance](./src/contracts/Governance.sol)
- [GovernancePowerStrategy](./src/contracts/GovernancePowerStrategy.sol)
- [VotingPortal](./src/contracts/VotingPortal.sol)

### Scripts

### Makefile


## Voting Network

### Scripts

### Makefile


## Execution Network

### Scripts

### Makefile