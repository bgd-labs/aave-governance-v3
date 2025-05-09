// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PermissionedPayloadsController, PayloadsControllerUtils, IPayloadsControllerCore, IPermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import '../GovBaseScript.sol';

abstract contract BaseDeployPermissionedPayloadsController is GovBaseScript {
  function GUARDIAN() public view virtual returns (address) {
    return msg.sender;
  }

  function PAYLOADS_MANAGER() public view virtual returns (address) {
    return msg.sender;
  }

  function DELAY() public view virtual returns (uint40) {
    return uint40(1 days);
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    CCCAddresses memory ccAddresses = _getCCAddresses(
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
        addresses.executorLvl1, // owner of proxy that will be deployed
        abi.encodeWithSelector(
          PermissionedPayloadsController.initialize.selector,
          GUARDIAN(),
          PAYLOADS_MANAGER(),
          executors
        ),
        Constants.PERMISSIONED_PAYLOADS_CONTROLLER_SALT
      );

    Ownable(addresses.permissionedExecutor).transferOwnership(
      addresses.permissionedPayloadsController
    );
  }
}

contract Ethereum is BaseDeployPermissionedPayloadsController {
  function GUARDIAN() public pure override returns (address) {
    return 0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF;
  }

  function PAYLOADS_MANAGER() public view virtual override returns (address) {
    return 0x22740deBa78d5a0c24C58C740e3715ec29de1bFa;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Base is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Gnosis is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Scroll is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Zksync is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Ethereum_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Base_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BASE_SEPOLIA;
  }
}

contract Optimism_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_SEPOLIA;
  }
}

contract Arbitrum_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_SEPOLIA;
  }
}

contract Metis_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Zksync_testnet is BaseDeployPermissionedPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZKSYNC_SEPOLIA;
  }
}
