// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import 'forge-std/Vm.sol';
import 'forge-std/StdJson.sol';
import {ChainIds, TestNetChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {DeployerHelpers, Addresses as CCCAddresses} from 'adi-deploy/scripts/BaseDeployerScript.sol';
// import {Create3Factory, Create3, ICreate3Factory} from 'solidity-utils/contracts/create3/Create3Factory.sol';

struct Network {
  string path;
  string name;
}

library GovDeployerHelpers {
  using stdJson for string;

  struct Addresses {
    address aavePool;
    uint256 chainId;
    address create3Factory;
    address dataWarehouse;
    address executorLvl1;
    address executorLvl2;
    address governance;
    address governanceDataHelper;
    address governanceImpl;
    address governancePowerStrategy;
    address guardian;
    address metaDelegateHelper;
    address owner;
    address payloadsController;
    address payloadsControllerDataHelper;
    address payloadsControllerImpl;
    address permissionedExecutor;
    address permissionedPayloadsController;
    address permissionedPayloadsControllerImpl;
    address proxyAdminGovernance;
    address proxyAdminPayloadsController;
    address votingMachine;
    address votingMachineDataHelper;
    address votingPortal_Eth_Avax;
    address votingPortal_Eth_BNB;
    address votingPortal_Eth_Eth;
    address votingPortal_Eth_Pol;
    address votingStrategy;
  }

  function getPathByChainId(
    uint256 chainId
  ) internal pure returns (string memory) {
    if (chainId == ChainIds.ETHEREUM) {
      return './deployments/gov/mainnet/eth.json';
    } else if (chainId == ChainIds.POLYGON) {
      return './deployments/gov/mainnet/pol.json';
    } else if (chainId == ChainIds.AVALANCHE) {
      return './deployments/gov/mainnet/avax.json';
    } else if (chainId == ChainIds.ARBITRUM) {
      return './deployments/gov/mainnet/arb.json';
    } else if (chainId == ChainIds.OPTIMISM) {
      return './deployments/gov/mainnet/op.json';
    } else if (chainId == ChainIds.METIS) {
      return './deployments/gov/mainnet/metis.json';
    } else if (chainId == ChainIds.BNB) {
      return './deployments/gov/mainnet/bnb.json';
    } else if (chainId == ChainIds.BASE) {
      return './deployments/gov/mainnet/base.json';
    } else if (chainId == ChainIds.GNOSIS) {
      return './deployments/gov/mainnet/gnosis.json';
    } else if (chainId == ChainIds.POLYGON_ZK_EVM) {
      return './deployments/gov/mainnet/zkevm.json';
    } else if (chainId == ChainIds.SCROLL) {
      return './deployments/gov/mainnet/zkevm.json';
    } else if (chainId == ChainIds.ZKSYNC) {
      return './deployments/gov/mainnet/zksync.json';
    } else if (chainId == ChainIds.LINEA) {
      return './deployments/gov/mainnet/linea.json';
    } else if (chainId == ChainIds.CELO) {
      return './deployments/gov/mainnet/celo.json';
    } else if (chainId == ChainIds.SONIC) {
      return './deployments/gov/mainnet/sonic.json';
    } else if (chainId == ChainIds.MANTLE) {
      return './deployments/gov/mainnet/mantle.json';
    } else if (chainId == ChainIds.INK) {
      return './deployments/gov/mainnet/ink.json';
    } else if (chainId == ChainIds.SONEIUM) {
      return './deployments/gov/mainnet/soneium.json';
    } else if (chainId == ChainIds.PLASMA) {
      return './deployments/gov/mainnet/plasma.json';
    }

    if (chainId == TestNetChainIds.ETHEREUM_SEPOLIA) {
      return './deployments/gov/testnet/sep.json';
    } else if (chainId == TestNetChainIds.POLYGON_AMOY) {
      return './deployments/gov/testnet/amoy.json';
    } else if (chainId == TestNetChainIds.AVALANCHE_FUJI) {
      return './deployments/gov/testnet/fuji.json';
    } else if (chainId == TestNetChainIds.ARBITRUM_SEPOLIA) {
      return './deployments/gov/testnet/arb_sep.json';
    } else if (chainId == TestNetChainIds.OPTIMISM_SEPOLIA) {
      return './deployments/gov/testnet/op_sep.json';
    } else if (chainId == TestNetChainIds.METIS_TESTNET) {
      return './deployments/gov/testnet/met_test.json';
    } else if (chainId == TestNetChainIds.BNB_TESTNET) {
      return './deployments/gov/testnet/bnb_test.json';
    } else if (chainId == TestNetChainIds.BASE_SEPOLIA) {
      return './deployments/gov/testnet/base_sep.json';
    } else if (chainId == TestNetChainIds.GNOSIS_CHIADO) {
      return './deployments/gov/testnet/gnosis_chiado.json';
    } else if (chainId == TestNetChainIds.SCROLL_SEPOLIA) {
      return './deployments/gov/testnet/scroll_sepolia.json';
    } else if (chainId == TestNetChainIds.ZKSYNC_SEPOLIA) {
      return './deployments/gov/testnet/zksync_sep.json';
    } else if (chainId == TestNetChainIds.SONIC_BLAZE) {
      return './deployments/gov/testnet/sonic_blaze.json';
    } else if (chainId == TestNetChainIds.MANTLE_SEPOLIA) {
      return './deployments/gov/testnet/mantle_sepolia.json';
    } else {
      revert('chain id is not supported');
    }
  }

  function decodeJson(
    string memory path,
    Vm vm
  ) internal view returns (Addresses memory) {
    string memory persistedJson = vm.readFile(path);

    Addresses memory addresses = Addresses({
      aavePool: abi.decode(persistedJson.parseRaw('.aavePool'), (address)),
      chainId: abi.decode(persistedJson.parseRaw('.chainId'), (uint256)),
      create3Factory: abi.decode(
        persistedJson.parseRaw('.create3Factory'),
        (address)
      ),
      dataWarehouse: abi.decode(
        persistedJson.parseRaw('.dataWarehouse'),
        (address)
      ),
      executorLvl1: abi.decode(
        persistedJson.parseRaw('.executorLvl1'),
        (address)
      ),
      executorLvl2: abi.decode(
        persistedJson.parseRaw('.executorLvl2'),
        (address)
      ),
      governance: abi.decode(persistedJson.parseRaw('.governance'), (address)),
      governanceDataHelper: abi.decode(
        persistedJson.parseRaw('.governanceDataHelper'),
        (address)
      ),
      governanceImpl: abi.decode(
        persistedJson.parseRaw('.governanceImpl'),
        (address)
      ),
      governancePowerStrategy: abi.decode(
        persistedJson.parseRaw('.governancePowerStrategy'),
        (address)
      ),
      guardian: abi.decode(persistedJson.parseRaw('.guardian'), (address)),
      metaDelegateHelper: abi.decode(
        persistedJson.parseRaw('.metaDelegateHelper'),
        (address)
      ),
      owner: abi.decode(persistedJson.parseRaw('.owner'), (address)),
      payloadsController: abi.decode(
        persistedJson.parseRaw('.payloadsController'),
        (address)
      ),
      payloadsControllerDataHelper: abi.decode(
        persistedJson.parseRaw('.payloadsControllerDataHelper'),
        (address)
      ),
      payloadsControllerImpl: abi.decode(
        persistedJson.parseRaw('.payloadsControllerImpl'),
        (address)
      ),
      permissionedExecutor: abi.decode(
        persistedJson.parseRaw('.permissionedExecutor'),
        (address)
      ),
      permissionedPayloadsController: abi.decode(
        persistedJson.parseRaw('.permissionedPayloadsController'),
        (address)
      ),
      permissionedPayloadsControllerImpl: abi.decode(
        persistedJson.parseRaw('.permissionedPayloadsControllerImpl'),
        (address)
      ),
      proxyAdminGovernance: abi.decode(
        persistedJson.parseRaw('.proxyAdminGovernance'),
        (address)
      ),
      proxyAdminPayloadsController: abi.decode(
        persistedJson.parseRaw('.proxyAdminPayloadsController'),
        (address)
      ),
      votingMachine: abi.decode(
        persistedJson.parseRaw('.votingMachine'),
        (address)
      ),
      votingMachineDataHelper: abi.decode(
        persistedJson.parseRaw('.votingMachineDataHelper'),
        (address)
      ),
      votingPortal_Eth_Avax: abi.decode(
        persistedJson.parseRaw('.votingPortal_Eth_Avax'),
        (address)
      ),
      votingPortal_Eth_BNB: abi.decode(
        persistedJson.parseRaw('.votingPortal_Eth_BNB'),
        (address)
      ),
      votingPortal_Eth_Eth: abi.decode(
        persistedJson.parseRaw('.votingPortal_Eth_Eth'),
        (address)
      ),
      votingPortal_Eth_Pol: abi.decode(
        persistedJson.parseRaw('.votingPortal_Eth_Pol'),
        (address)
      ),
      votingStrategy: abi.decode(
        persistedJson.parseRaw('.votingStrategy'),
        (address)
      )
    });

    return addresses;
  }

  function encodeJson(
    string memory path,
    Addresses memory addresses,
    Vm vm
  ) internal {
    string memory json = 'addresses';
    json.serialize('aavePool', addresses.aavePool);
    json.serialize('chainId', addresses.chainId);
    json.serialize('create3Factory', addresses.create3Factory);
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
    json.serialize('payloadsControllerImpl', addresses.payloadsControllerImpl);
    json.serialize('permissionedExecutor', addresses.permissionedExecutor);
    json.serialize(
      'permissionedPayloadsController',
      addresses.permissionedPayloadsController
    );
    json.serialize(
      'permissionedPayloadsControllerImpl',
      addresses.permissionedPayloadsControllerImpl
    );
    json.serialize('proxyAdminGovernance', addresses.proxyAdminGovernance);
    json.serialize(
      'proxyAdminPayloadsController',
      addresses.proxyAdminPayloadsController
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
    vm.writeJson(json, path);
  }

  function getAddresses(
    uint256 networkId,
    Vm vm
  ) internal view returns (GovDeployerHelpers.Addresses memory) {
    return
      GovDeployerHelpers.decodeJson(
        GovDeployerHelpers.getPathByChainId(networkId),
        vm
      );
  }
}

library Constants {
  bytes32 public constant CREATE3_FACTORY_SALT =
    keccak256(bytes('Create3 Factory'));
  bytes32 public constant GOVERNANCE_SALT =
    keccak256(bytes('Aave Governance core'));
  bytes32 public constant POWER_STRATEGY_SALT =
    keccak256(bytes('Aave Power Strategy'));
  bytes32 public constant VOTING_MACHINE_SALT =
    keccak256(bytes('Aave Voting Machine'));
  bytes32 public constant VOTING_STRATEGY_SALT =
    keccak256(bytes('Aave Voting Strategy'));
  bytes32 public constant DATA_WAREHOUSE_SALT =
    keccak256(bytes('Aave Data Warehosue'));
  bytes32 public constant VOTING_PORTAL_ETH_ETH_SALT =
    keccak256(bytes('Aave Voting portal eth-eth merkle update'));
  bytes32 public constant VOTING_PORTAL_ETH_AVAX_SALT =
    keccak256(bytes('Aave Voting portal eth-avax merkle update'));
  bytes32 public constant VOTING_PORTAL_ETH_POL_SALT =
    keccak256(bytes('Aave Voting portal eth-pol merkle update'));
  bytes32 public constant VOTING_PORTAL_ETH_BNB_SALT =
    keccak256(bytes('Aave Voting portal eth-bnb'));
  bytes32 public constant PAYLOADS_CONTROLLER_SALT =
    keccak256(bytes('Aave Payloads Controller'));
  bytes32 public constant PERMISSIONED_PAYLOADS_CONTROLLER_SALT =
    keccak256(bytes('Aave Permissioned Payloads Controller'));
  bytes32 public constant PERMISSIONED_EXECUTOR_SALT =
    keccak256(bytes('Aave Permissioned Executor'));
  bytes32 public constant EXECUTOR_LVL1_SALT =
    keccak256(bytes('Aave Executor Lvl 1'));
  bytes32 public constant EXECUTOR_LVL2_SALT =
    keccak256(bytes('Aave Executor Lvl 2'));
  bytes32 public constant GOV_DATA_HELPER_SALT =
    keccak256(bytes('Aave Governance data helper'));
  bytes32 public constant VM_DATA_HELPER_SALT =
    keccak256(bytes('Aave Voting Machine data helper'));
  bytes32 public constant PC_DATA_HELPER_SALT =
    keccak256(bytes('Aave Payloads Controller data helper'));
  bytes32 public constant MD_DATA_HELPER_SALT =
    keccak256(bytes('Aave Meta Delegate data helper'));
}

abstract contract GovBaseScript is Script {
  function TRANSACTION_NETWORK() public view virtual returns (uint256);

  function getAddresses(
    uint256 networkId
  ) external view returns (GovDeployerHelpers.Addresses memory) {
    return
      GovDeployerHelpers.decodeJson(
        GovDeployerHelpers.getPathByChainId(networkId),
        vm
      );
  }

  function _getCCAddresses(
    uint256 networkId
  ) internal view returns (CCCAddresses memory) {
    return
      DeployerHelpers.decodeJson(
        DeployerHelpers.getPathByChainId(networkId),
        vm
      );
  }

  function _getAddresses(
    uint256 networkId
  ) internal view returns (GovDeployerHelpers.Addresses memory) {
    try this.getAddresses(networkId) returns (
      GovDeployerHelpers.Addresses memory addresses
    ) {
      return addresses;
    } catch (bytes memory) {
      GovDeployerHelpers.Addresses memory empty;
      return empty;
    }
  }

  function _setAddresses(
    uint256 networkId,
    GovDeployerHelpers.Addresses memory addresses
  ) internal {
    GovDeployerHelpers.encodeJson(
      GovDeployerHelpers.getPathByChainId(networkId),
      addresses,
      vm
    );
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal virtual;

  function run() public {
    vm.startBroadcast();
    // ----------------- Persist addresses -----------------------------------------------------------------------------
    GovDeployerHelpers.Addresses memory addresses = _getAddresses(
      TRANSACTION_NETWORK()
    );
    // -----------------------------------------------------------------------------------------------------------------
    _execute(addresses);
    // ----------------- Persist addresses -----------------------------------------------------------------------------
    _setAddresses(TRANSACTION_NETWORK(), addresses);
    // -----------------------------------------------------------------------------------------------------------------
    vm.stopBroadcast();
  }
}
