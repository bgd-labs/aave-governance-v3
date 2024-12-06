// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PermissionedPayloadsController, PayloadsControllerUtils, IPayloadsControllerCore, IPermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import '../GovBaseScript.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

abstract contract BaseDeployermissionedPayloadsController is GovBaseScript {
  function DELAY() public view virtual returns (uint40) {
    return uint40(1 days);
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    DeployerHelpers.Addresses memory ccAddresses = _getCCAddresses(
      TRANSACTION_NETWORK()
    );

    addresses.permissionedPayloadsControllerImpl = address(
      new PermissionedPayloadsController()
    );

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        executor: addresses.permissionedExecutor,
        delay: DELAY()
      })
    });

    addresses.permissionedPayloadsController = TransparentProxyFactory(
      ccAddresses.proxyFactory
    ).createDeterministic(
        addresses.permissionedPayloadsControllerImpl,
        ccAddresses.proxyAdmin,
        abi.encodeWithSelector(
          PermissionedPayloadsController.initialize.selector,
          addresses.guardian,
          msg.sender,
          executors
        ),
        Constants.PERMISSIONED_PAYLOADS_CONTROLLER_SALT
      );

    Ownable(addresses.permissionedExecutor).transferOwnership(
      addresses.permissionedPayloadsController
    );
  }
}

contract Ethereum is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Base is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Gnosis is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Scroll is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Zksync is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZK_SYNC;
  }
}

contract Ethereum_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Optimism_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_GOERLI;
  }
}

contract Arbitrum_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_GOERLI;
  }
}

contract Metis_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Base_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BASE_GOERLI;
  }
}

contract Zksync_testnet is BaseDeployermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZK_SYNC_SEPOLIA;
  }
}