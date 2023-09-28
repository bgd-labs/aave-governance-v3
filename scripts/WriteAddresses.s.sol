// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './GovBaseScript.sol';

contract WriteDeployedAddresses is Script {
  using stdJson for string;

  function run() public {
    Network[] memory networks = new Network[](12);
    // mainnets
    networks[0] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.ETHEREUM),
      name: 'ethereum'
    });
    networks[1] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.POLYGON),
      name: 'polygon'
    });
    networks[2] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.AVALANCHE),
      name: 'avalanche'
    });
    networks[3] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.OPTIMISM),
      name: 'optimism'
    });
    networks[4] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.ARBITRUM),
      name: 'arbitrum'
    });
    networks[5] = Network({
      path: GovDeployerHelpers.getPathByChainId(ChainIds.METIS),
      name: 'metis'
    });
    // testnets
    networks[6] = Network({
      path: GovDeployerHelpers.getPathByChainId(
        TestNetChainIds.ETHEREUM_SEPOLIA
      ),
      name: 'sepolia'
    });
    networks[7] = Network({
      path: GovDeployerHelpers.getPathByChainId(TestNetChainIds.POLYGON_MUMBAI),
      name: 'mumbai'
    });
    networks[8] = Network({
      path: GovDeployerHelpers.getPathByChainId(TestNetChainIds.AVALANCHE_FUJI),
      name: 'fuji'
    });
    networks[9] = Network({
      path: GovDeployerHelpers.getPathByChainId(
        TestNetChainIds.OPTIMISM_GOERLI
      ),
      name: 'optimismGoerli'
    });
    networks[10] = Network({
      path: GovDeployerHelpers.getPathByChainId(
        TestNetChainIds.ARBITRUM_GOERLI
      ),
      name: 'arbitrumGoerli'
    });
    networks[11] = Network({
      path: GovDeployerHelpers.getPathByChainId(TestNetChainIds.METIS_TESTNET),
      name: 'metisTestnet'
    });

    string memory deployedJson = 'deployments';

    for (uint256 i = 0; i < networks.length; i++) {
      GovDeployerHelpers.Addresses memory addresses = GovDeployerHelpers
        .decodeJson(networks[i].path, vm);
      string memory json = networks[i].name;

      json.serialize('aavePool', addresses.aavePool);
      json.serialize('chainId', addresses.chainId);
      json.serialize('dataWarehouse', addresses.dataWarehouse);
      json.serialize('executorLvl1', addresses.executorLvl1);
      json.serialize('executorLvl2', addresses.executorLvl2);
      json.serialize('governance', addresses.governance);
      json.serialize('governanceDataHelper', addresses.governanceDataHelper);
      json.serialize('governanceImpl', addresses.governanceImpl);
      json.serialize(
        'governancePowerStrategy',
        addresses.governancePowerStrategy
      );
      json.serialize('guardian', addresses.guardian);
      json.serialize('metaDelegateHelper', addresses.metaDelegateHelper);
      json.serialize('owner', addresses.owner);
      json.serialize('payloadsController', addresses.payloadsController);
      json.serialize(
        'payloadsControllerDataHelper',
        addresses.payloadsControllerDataHelper
      );
      json.serialize(
        'payloadsControllerImpl',
        addresses.payloadsControllerImpl
      );
      json.serialize('votingMachine', addresses.votingMachine);
      json.serialize(
        'votingMachineDataHelper',
        addresses.votingMachineDataHelper
      );
      json.serialize('votingPortal_Eth_Avax', addresses.votingPortal_Eth_Avax);
      json.serialize('votingPortal_Eth_BNB', addresses.votingPortal_Eth_BNB);
      json.serialize('votingPortal_Eth_Eth', addresses.votingPortal_Eth_Eth);
      json.serialize('votingPortal_Eth_Pol', addresses.votingPortal_Eth_Pol);
      json = json.serialize('votingStrategy', addresses.votingStrategy);

      if (i == networks.length - 1) {
        deployedJson = deployedJson.serialize(networks[i].name, json);
      } else {
        deployedJson.serialize(networks[i].name, json);
      }
    }

    vm.writeJson(deployedJson, './deployments/multiChainGovV3Addresses.json');
  }
}
