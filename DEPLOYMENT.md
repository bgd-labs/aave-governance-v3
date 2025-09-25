# Deployment of the Aave Governance V3 Contracts

This document covers deployment steps for the Aave Governance system components:

- [Governance](./DEPLOYMENT.md#governance-network)
- [Voting](./DEPLOYMENT.md#voting-network)
- [Execution](./DEPLOYMENT.md#execution-network)

# Deployment order

## Prerequisites

1. [Setup Environment](./DEPLOYMENT.md#setup) - Configure `.env`, `foundry.toml`, and scripts
2. [Initial Scripts](./DEPLOYMENT.md#initial-scripts) - Generate network address JSON files

## Core Deployment

3. [Governance Network](./DEPLOYMENT.md#governance-network) - Deploy on Ethereum (central hub)
4. [Voting Network](./DEPLOYMENT.md#voting-network) - Deploy on voting chains (requires Governance + aDI)
5. [Execution Network](./DEPLOYMENT.md#execution-network) - Deploy on execution chains (requires Governance + aDI)

## Optional

6. [Permissioned Execution](./DEPLOYMENT.md#permissioned-execution) - Alternative execution with specified address control
7. [Helpers](./DEPLOYMENT.md#helpers) - UI query helper contracts

# Setup

Configure these files before deployment:

- *.env*: copy [.env.example](./.env.example) into `.env` file, and populate it. Use `MNEMONIC_INDEX` and `LEDGER_SENDER` for manual wallet confirmation, or include the private key if you want an automated deployment (instructions for choosing between deployment methods are provided later).
  
- *[foundry.toml](./foundry.toml)*: when adding a new network, include the respective definitions (`rpc_endpoints` and `etherscan`). Add network configuration to the `etherscan` section only if the network isn't supported by Etherscan. For networks requiring special configuration, add them under the network profile section.
  
- *scripts*: the deployment scripts for the different parts of the system are located in the [scripts](./scripts/) folder. 
If you are adding a new network, first verify that the network exists in the [Solidity Utils](https://github.com/bgd-labs/solidity-utils/blob/main/src/contracts/utils/ChainHelpers.sol) repository, then add a new network script to [InitialDeployment.s.sol](./scripts/InitialDeployments.s.sol). The deployment scripts retrieve necessary addresses from generated JSON files in the [deployments](./deployments/) folder, so you must follow the strict deployment order, that will be specified later. After deployment, the scripts save the newly deployed addresses to the JSON files.

- *deployments*: The [deployments](./deployments/) folder contains the deployed addresses for every network. Note that the JSON files are modified during execution or simulation. If simulation runs but execution fails, the addresses will still be modified.
  Note that here is a dependency on [aDI](https://github.com/aave-dao/adi-deploy/tree/main/deployments) addresses, taken from [address book](https://github.com/bgd-labs/aave-address-book) or added to [InitialDeployment](./scripts/InitialDeployments.s.sol) script.
  
- *Makefile*: The [Makefile](./Makefile) contains commands for deploying each smart contract to a selected network. To deploy smart contracts to a new network, first add the necessary network scripts, then change the network name in the relevant command and execute it. You can deploy using a private key or using a ledger (by adding  `LEDGER=true` to the execution command). If you deploy into a mainnet network, add: `PROD=true`. Set the gwei amount for transactions if needed.

Here's an example of the initial command that generates network address JSON files:

```
deploy-initial:
	$(call deploy_fn,InitialDeployments,ethereum polygon avalanche arbitrum optimism metis base binance gnosis)
```
Include only your target network(s) in this command. Multiple networks will deploy sequentially.

Execution command example: `make deploy-initial PROD=true LEDGER=true`

## Notes

- Some contracts require addresses from previously deployed contracts (including those on other networks) for proper communication. Therefore, follow the specified deployment order strictly.

# Initial Scripts

As previously said, add the new network script to `InitialDeployments` and execute the initial script only for a new network (since doing it for existing ones would overwrite the addresses JSON of the specified network with address(0)). The initial script creates a new addresses JSON for the new network.

- execution command: `make deploy-initial PROD=true LEDGER=true` 

# Governance Network

The governance network is the central hub where Aave Governance is managed (see details [here](./docs/overview.md#core-network)). 
Required contracts:
- [Governance](./src/contracts/Governance.sol)
- [GovernancePowerStrategy](./src/contracts/GovernancePowerStrategy.sol)
- [VotingPortal](./src/contracts/VotingPortal.sol)

Other networks use the Governance contract address for voting and execution to validate that received messages come from the correct Governance source.

## Scripts

**Prerequisites**: Governance deployment requires prior aDI deployment.

**Important**: Deploy Governance only on Ethereum, which serves as the central hub for the Governance system. Use these scripts only when updating Governance implementation or changing/adding connected voting networks.

To deploy on a new network, add the network scripts to:

- [Deploy_Gov_PowerStrategy.s.sol](./scripts/Governance/Deploy_Gov_PowerStrategy.s.sol): Deploys the Governance power strategy contract to validate user voting power.

- [DeployGovernance.s.sol](./scripts/Governance/Deploy_Governance.s.sol): Deploys governance contracts using TransparentProxyFactory. Requires owner and guardian from InitialDeployments script, the governance power strategy from the previous step, and the CrossChainController address.
  
- [Deploy_VotingPortals.s.sol](./scripts/Governance/Deploy_VotingPortals.s.sol): Deploys voting portals using Create3. Since VotingMachine needs the VotingPortal address, and VotingPortal needs the VotingMachine address (circular dependency), Create3 allows predicting the portal address before deployment using `addressOfWithPreDeployedFactory`, so VotingMachine can be deployed first with the predicted address, then VotingPortal is deployed with the same salt to get the exact predicted address.

To set the voting portals as governance portals:

- [Set_VotingPortals_on_Gov.s.sol](./scripts/Governance/Set_VotingPortals_on_Gov.s.sol): Sets the deployed voting portals in the Governance contract, connecting Governance to the VotingMachines. Only executable if msg.sender is still the owner of the Governance contract. Change owners and guardians **only after completing all settings** for first deployment.

To set the governance to cross-chain system:

- [Set_Gov_as_CCF_Sender.s.sol](./scripts/governance/Set_Gov_as_CCF_Sender.s.sol): Sets Governance as a valid sender to aDI (only if msg.sender is owner of aDI). Required because Governance directly sends messages for payload execution.
- [Set_VP_as_CCF_Senders.s.sol](./scripts/Governance/Set_VP_as_CCF_Senders.s.sol): Sets VotingPortals as valid senders to aDI (only if msg.sender is owner of aDI). Required because VotingPortals send messages for voting start.

## Makefile

Specify the required networks in the Makefile:

- `make deploy-gov-power-strategy PROD=true LEDGER=true`: deploys the governance power strategy 
- `make deploy-governance PROD=true LEDGER=true`: deploys governance
- `make set-gov-as-cff-sender PROD=true LEDGER=true`: sets governance as sender in aDI
- `make deploy-voting-portals PROD=true LEDGER=true`: deploys voting portals (comment or select networks as needed). Execute this after VotingMachine is deployed or already exists on the specified network.
- `make set-vp-on-gov PROD=true LEDGER=true`: sets the voting portals as governance portals
- `make set-vp-as_ccf-senders PROD=true LEDGER=true`: sets the voting portals as senders in aDI


# Voting Network

The voting network consists of the contracts to enable voting on proposals (more details [here](./docs/overview.md#aave-voting-networks)). The required contracts are:

- [DataWarehouse](./src/contracts/voting/DataWarehouse.sol)
- [VotingStrategy](./src/contracts/voting/VotingStrategy.sol)
- [VotingMachine](./src/contracts/voting/VotingMachine.sol)

## Scripts

**Prerequisites**: Voting network deployment requires prior Governance and aDI deployment.

To deploy a new voting network (or a new voting machine on the same network, since they are not upgradeable), add the specified networks to these scripts:

- [Deploy_DataWarehouse.s.sol](./scripts/VotingMachine/Deploy_DataWarehouse.s.sol): Deploys the DataWarehouse contract, that holds the proofs to validate the votes.
- [Deploy_VotingStrategy.s.sol](./scripts/VotingMachine/Deploy_VotingStrategy.s.sol): Deploys the VotingStrategy contract, that holds the logic to account for the voting power of the users. Requires prior DataWarehouse deployment.
- [Deploy_VotingMachine.s.sol](./scripts/VotingMachine/Deploy_VotingMachine.s.sol): Deploys the VotingMachine contract. Requires prior DataWarehouse and VotingStrategy deployment. Uses Create3 library to determine the future address of the connected VotingPortal.

To connect the VotingMachine with the cross-chain system:

- [Set_VM_as_CCF_Sender.s.sol](./scripts/VotingMachine/Set_VM_as_CCF_Sender.s.sol): Sets the VotingMachine as sender to aDI (only if msg.sender is owner of aDI) so it can send voting results.

## Makefile

Specify the required networks in the Makefile:

- `make deploy-data-warehouse PROD=true LEDGER=true`: deploys the data warehouse contract
- `make deploy-voting-strategy PROD=true LEDGER=true`: deploys the voting strategy contract
- `make deploy-voting-machine PROD=true LEDGER=true`: deploys the voting machine contract
- `make set-vm-as-ccf-sender PROD=true LEDGER=true`: sets the voting machine as sender in aDI

# Execution Network

The execution network consists of contracts that execute specified payloads (more details [here](./docs/overview.md#aave-execution-networks)). The required contracts are:

- [Executor.sol](./src/contracts/payloads/Executor.sol)
- [PayloadsController.sol](./src/contracts/payloads/PayloadsController.sol)

## Scripts

**Prerequisites**: Execution network deployment requires prior Governance and aDI deployment.

**Important**: Executor contracts hold permissions for all changes that payloads will execute.

To deploy a new execution network (or a new implementation), add the specified networks to these scripts:

- [Deploy_ExecutorLvl1.s.sol](./scripts/Payloads/Deploy_ExecutorLvl1.s.sol): Deploys executor level 1 contract (required on all networks). Sets defined owner from JSON as initial owner, but transfer executor ownership to PayloadsController after deployment.
- [Deploy_ExecutorLvl2.s.sol](./scripts/Payloads/Deploy_ExecutorLvl2.s.sol): Deploys executor level 2 contract (deployed only on Ethereum).
- [Deploy_PayloadsController.s.sol](./scripts/Payloads/Deploy_PayloadsController.s.sol): Deploys PayloadsController contract. Sets executor level 1 as owner and proxy owner.

## Makefile

Specify the required networks in the Makefile:

- `make deploy-executor-lvl1 PROD=true LEDGER=true`: deploys executor contract and saves it as executor level 1
- `make deploy-executor-lvl2 PROD=true LEDGER=true`: deploys executor contract and saves it as executor level 2
- `make deploy-payloads-controller-chain PROD=true LEDGER=true`: deploys PayloadsController contract.

# Permissioned Execution

A permissioned execution can also be deployed on a network. This simulates the same process as a governance-controlled execution network, but with control given to a specified address (more details [here](./docs/permissioned-payloads-controller-overview.md)).

- [PermissionedPayloadsController.sol](./src/contracts/payloads/PermissionedPayloadsController.sol)

## Scripts

To deploy a permissioned execution network you need the following scripts:

- [Deploy_PermissionedExecutor.s.sol](./scripts/Payloads/Deploy_PermissionedExecutor.s.sol): Deploys the executor contract as executor level 1. Sets defined owner from JSON as initial owner, but transfer executor ownership to PermissionedPayloadsController after deployment.
- [Deploy_PermissionedPayloadsController.s.sol](./scripts/Payloads/Deploy_PermissionedPayloadsController.s.sol): Deploys PermissionedPayloadsController. Sets executor as proxy owner and msg.sender as Payloads Manager.

## Makefile

- `make deploy-permissioned-executor PROD=true LEDGER=true`: deploys executor contract, and saves it as executor level 1
- `make deploy-permissioned-payloads-controller PROD=true LEDGER=true`: deploys PermissionedPayloadsController contract

# Helpers

The helper contracts enable the UI to query the governance system state more easily. The available helper contracts are:

- [GovernanceDataHelper.sol](./src/contracts/dataHelpers/GovernanceDataHelper.sol)
- [PayloadsControllerDataHelper.sol](./src/contracts/dataHelpers/PayloadsControllerDataHelper.sol)
- [VotingMachineDataHelper.sol](./src/contracts/dataHelpers/VotingMachineDataHelper.sol)

## Scripts

- [Deploy_ContractHelpers.s.sol](./scripts/Deploy_ContractHelpers.s.sol): Deploys all necessary helper contracts depending on whether the network has Governance, VotingMachine, and/or PayloadsController.

## Makefile

Specify the required networks in the Makefile:

- `make deploy-helper-contracts PROD=true LEDGER=true`: deploys helpers contracts

# Other scripts

Other scripts:

- `make update-executor-owner PROD=true LEDGER=true`: changes executor ownership to PayloadsController.
