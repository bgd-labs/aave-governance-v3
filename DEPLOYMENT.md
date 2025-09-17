# Deployment of the Aave Governance V3 Contracts

On this document we will specify the different steps needed to deploy the different parts of the Aave Governance system, consisting on:

- [Governance](./DEPLOYMENT.md#governance-network)
- [Voting](./DEPLOYMENT.md#voting-network)
- [Execution](./DEPLOYMENT.md#execution-network)

## Setup

There are a few things to take into account that will need to be updated / modified for deployments on different networks.

- *.env*: copy [.env.example](./.env.example) into `.env` file, and fill it. the private key is only need if you want to deploy with it. If not you only need to fill `MNEMONIC_INDEX` and `LEDGER_SENDER` (specified later on how to choose between the two ways of deployment)
- *[foundry.toml](./foundry.toml)*: when adding a new network, you should also add the respective definitions (rpc_endpoints and etherscan). Under the etherscan section you should only add the network configuration if its not supported by etherscan. If there is a network that needs special configuration, add it there also, under the network profile.
- *scripts*: These can be found in the folder [scripts](./scripts/). Here you will find the deployment scripts needed for the different parts of the system.
If you are adding a new network, you will first need to double check that the nework is added in [Solidity Utils](https://github.com/bgd-labs/solidity-utils/blob/main/src/contracts/utils/ChainHelpers.sol) repository, add the network path in [GovBaseScript](), and then add a new network script in [InitialDeployment.s.sol](). When using the scripts for the deployments, they will get the necessary addresses from the generated json files under [deployments](./deployments/) folder, so it is necessary to follow the strict deployment order, that will be specified later. After deployment, the scripts save the new deployed addresses in the mentioned json files.
- *deployments*: The [deployments](./deployments/) folder contains the deployed addresses for every network. Its important to take into account that the json files will be modified with the script execution or simulation, so if there is a simulation but execution fails, the addresses will be modified. Also take into account that there is a dependency on [aDI](https://github.com/aave-dao/adi-deploy/tree/main/deployments) addresses, taken from [address book](https://github.com/bgd-labs/aave-address-book) or added in [InitialDeployment](./scripts/InitialDeployments.s.sol) script.
- *Makefile*: This can be found [here](./Makefile). I has the commands to be able to deploy each smart contract for the selected network. If you need to deploy any of the smart contracts to a new network, (after you have added the necessary network scripts), you just need to change the network name in the necessary command and execute it.
You can deploy using a private key or a ledger by adding `LEDGER=true` to the execution command. If you want to deploy into a mainnet network, you would need to add: `PROD=true`. You can also set the specific gwei amount to pay for the transaction.

You can see here an example of executing the first command that you need that will generate the specified network addresses json:

```
deploy-initial:
	$(call deploy_fn,InitialDeployments,ethereum polygon avalanche arbitrum optimism metis base binance gnosis)
```
In this case you would need to only have the network that you want to deploy on. If you leave multiple networks in the command, it will deploy on all of them sequentially.

Execution command would look like this: `make deploy-initial PROD=true LEDGER=true`

### Notes

- It is very important to follow the order specified for the deployments. As there are some contracts that need addresses of previously deployed contracts (even on other networks) for correct communication.

## Initial Scripts

As previously said, you should add the new network script to `InitialDeployments` and execute the initial script only for new network (as doing for existing ones would rewrite the addresses json of the specified network with address(0)). This will create a new addresses json for the new network.

- execution command: `make deploy-initial PROD=true LEDGER=true` 

## Governance Network

The governance network is the central hub where Aave Governance is managed (more [here](./docs/overview.md#core-network)). The contracts needed for it to work are:
- [Governance](./src/contracts/Governance.sol)
- [GovernancePowerStrategy](./src/contracts/GovernancePowerStrategy.sol)
- [VotingPortal](./src/contracts/VotingPortal.sol)

The address of the Governance contract will be used on deployments of other networks, for voting and execution, so as to validate that messages received come from the correct address (Governance).

### Scripts

To deploy on a new network you will need to add the network scripts to (Take into account that Governance should not be deployed on other networks as Ethereum is the one used as central hub for the Governance system. So you will only need this scripts when needed to update Governance implementation, or to change / add connected voting networks):
(To correctly deploy governance it requires aDi to have been previously deployed)

- [Deploy_Gov_PowerStrategy.s.sol](./scripts/Governance/Deploy_Gov_PowerStrategy.s.sol): Deploys the Governance power strategy contract used to check the power of a user.
- [DeployGovernance.s.sol](./scripts/Governance/Deploy_Governance.s.sol): Deploys the governance contracts, using the TransparentProxyFactory. It uses the owner and guardian set on InitialDeployments script, and the governance power strategy deployed in previous step. It also needs the address of the CrossChainController.
- [Deploy_VotingPortals.s.sol](./scripts/Governance/Deploy_VotingPortals.s.sol): Deploys the voting portals specified. It deploys using Create3 as it uses the address of the votingMachine of the specified network. (This works because on the deployment order we will first deploy the voting machine, using the Create3 `addressOfWithPreDeployedFactory` method to get the address of the futurely deployed voting portal. Then once we deploy the voting portal, as we will use the same salt and same Create3 factory we will get the same address used in VotingMachine. Create3 is needed because of this circular dependency).

To set the voting portals as governance portals:

- [Set_VotingPortals_on_Gov.s.sol](./scripts/Governance/Set_VotingPortals_on_Gov.s.sol): This script sets the deployed voting portals in the Governance, connecting this way, Governance to the VotingMachines. (This is only executable if msg.sender is still the owner of Governance contract. Thats why its important to only change owners / guardians after all settings are done (for first deployment)).

To set the governance to cross chain system:

- [Set_Gov_as_CCF_Sender.s.sol](./scripts/governance/Set_Gov_as_CCF_Sender.s.sol): This script sets Governance as a valid sender to aDI (only if msg.sender is owner of aDI). This is needed as Governance directly sends the message for Payload execution.
- [Set_VP_as_CCF_Senders.s.sol](./scripts/Governance/Set_VP_as_CCF_Senders.s.sol): This script sets VotingPortals as valid senders to aDI (only if msg.sender is owner of aDI). This is needed as VotingPortals send the messages for voting start.

### Makefile

Remember to specify the networks needed on the Makefile.

- `make deploy-gov-power-strategy PROD=true LEDGER=true`: deploys the governance power strategy 
- `make deploy-governance PROD=true LEDGER=true`: deploys governance
- `make set-gov-as-cff-sender PROD=true LEDGER=true`: sets governance as sender in aDI
- `make deploy-voting-portals PROD=true LEDGER=true`: deploys voting portals (comment or select networks as needed). This command should be executed once a voting machine is deployed (or if it already exists on the specified network)
- `make set-vp-on-gov PROD=true LEDGER=true`: sets the voting portals as governance portals
- `make set-vp-as_ccf-senders PROD=true LEDGER=true`: sets the voting portals as senders in aDI


## Voting Network

The voting network consist on the contracts to make voting on proposals possible (more [here](./docs/overview.md#aave-voting-networks)). The contracts needed for it to work are:

- [DataWarehouse](./src/contracts/voting/DataWarehouse.sol)
- [VotingStrategy](./src/contracts/voting/VotingStrategy.sol)
- [VotingMachine](./src/contracts/voting/VotingMachine.sol)

### Scripts

To deploy a new voting network (or a new voting machine in same network, as they are not upgradeable) you will need to add the specified networks to these scripts:
(To correctly deploy a voting network it requires to have governance and aDI previously deployed)

- [Deploy_DataWarehouse.s.sol](./scripts/VotingMachine/Deploy_DataWarehouse.s.sol): Deploys the DataWarehouse contract, that holds the proofs to validate the votes.
- [Deploy_VotingStrategy.s.sol](./scripts/VotingMachine/Deploy_VotingStrategy.s.sol): Deploys the VotingStrategy contract, that holds the logic to account for the voting power of the users. Depends on having previously deployed the DataWarehouse.
- [Deploy_VotingMachine.s.sol](./scripts/VotingMachine/Deploy_VotingMachine.s.sol): Deploys the VotingMachine contract, depends on previously having deployed the DataWarehouse and VotingStrategy. It uses Create3 library to determine the future address of the connected VotingPortal.

To connect the VotingMachine with the cross chain system:

- [Set_VM_as_CCF_Sender.s.sol](./scripts/VotingMachine/Set_VM_as_CCF_Sender.s.sol): Sets the VotingMachine as sender to aDI (only if msg.sender is owner of aDI), so that it can send the voting results.

### Makefile

Remember to specify the networks needed on the Makefile.

- `make deploy-data-warehouse PROD=true LEDGER=true`: deploys the data warehouse contract
- `make deploy-voting-strategy PROD=true LEDGER=true`: deploys the voting strategy contract
- `make deploy-voting-machine PROD=true LEDGER=true`: deploys the voting machine contract
- `make set-vm-as-ccf-sender PROD=true LEDGER=true`: sets the voting machine as sender in aDI

## Execution Network

The execution network consist on the contracts that will be able to execute specified payloads (more [here](./docs/overview.md#aave-execution-networks)). The contracts needed for it to work are:

- [Executor.sol](./src/contracts/payloads/Executor.sol)
- [PayloadsController.sol](./src/contracts/payloads/PayloadsController.sol)

### Scripts

To deploy a new execution network (or a new implementation) you will need to add the specified networks to these scripts:
(To correctly deploy an execution network it requires to have governance and aDI previously deployed).
(Its important to note that the executor contracts are the ones that will hold permissions over whatever changes the payloads will need to do)

- [Deploy_ExecutorLvl1.s.sol](./scripts/Payloads/Deploy_ExecutorLvl1.s.sol): Deploys the executor contract as executor 1. (Needed on all networks). Sets defined owner on json as owner, but at the end of deployment, owner of executor should be set to the PayloadsController.
- [Deploy_ExecutorLvl2.s.sol](./scripts/Payloads/Deploy_ExecutorLvl2.s.sol): Deploys the executor contract as executor 2. (only deployed on Ethereum)
- [Deploy_PayloadsController.s.sol](./scripts/Payloads/Deploy_PayloadsController.s.sol): Deploys PayloadsController contract. Sets executor 1 as owner, and as proxy owner.

### Makefile

Remember to specify the networks needed on the Makefile.

- `make deploy-executor-lvl1 PROD=true LEDGER=true`: deploys executor contract, and saves it as executorLvl1
- `make deploy-executor-lvl2 PROD=true LEDGER=true`: deploys executor contract, and saves it as executorLvel2
- `make deploy-payloads-controller-chain PROD=true LEDGER=true`: deploys PayloadsController contract.

## Permissioned Execution

A permissioned execution can also be deployed on a network. This will simulate the same process as a normal governance controlled execution network, but with the control given to a determined address (more [here](./docs/permissioned-payloads-controller-overview.md)).

- [PermissionedPayloadsController.sol](./src/contracts/payloads/PermissionedPayloadsController.sol)

### Scripts

To deploy a permissioned execution network you need the following scripts:

- [Deploy_PermissionedExecutor.s.sol](./scripts/Payloads/Deploy_PermissionedExecutor.s.sol): Deploys the executor contract as executor1. Sets defined owner on json as owner, but at the end of deployment, owner of executor should be set to the PermissionedPayloadsController.
- [Deploy_PermissionedPayloadsController.s.sol](./scripts/Payloads/Deploy_PermissionedPayloadsController.s.sol): Deploys PermissionedPayloadsController. Sets executor as owner of proxy. Sets msg.sender as Payloads Manager.

### Makefile

- `make deploy-permissioned-executor PROD=true LEDGER=true`: deploys executor contract, and saves it as executorLvl1.
- `make deploy-permissioned-payloads-controller PROD=true LEDGER=true`: deploys PermissionedPayloadsController contract.

## Helpers

The helpers contracts are used to help ui make easier queries on the state of the governance system. The helpers contracts that exist are:

- [GovernanceDataHelper.sol](./src/contracts/dataHelpers/GovernanceDataHelper.sol)
- [PayloadsControllerDataHelper.sol](./src/contracts/dataHelpers/PayloadsControllerDataHelper.sol)
- [VotingMachineDataHelper.sol](./src/contracts/dataHelpers/VotingMachineDataHelper.sol)

### Scripts

- [Deploy_ContractHelpers.s.sol](./scripts/Deploy_ContractHelpers.s.sol): script that will deploy all the necessary helper contracts depending on if the network has Governance, VotingMachine and / or PayloadsController.

### Makefile

Remember to specify the networks needed on the Makefile.

- `make deploy-helper-contracts PROD=true LEDGER=true`:

## Others

There are other scripts that help on:

- changing ownership of the executor to PayloadsController: `make update-executor-owner PROD=true LEDGER=true`