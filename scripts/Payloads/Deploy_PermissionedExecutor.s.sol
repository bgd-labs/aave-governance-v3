// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';

abstract contract BaseDeployPermissionedExecutor is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.permissionedExecutor = address(new Executor());
  }
}

contract Ethereum is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Base is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Binance is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Gnosis is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Zksync is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Scroll is BaseDeployPermissionedExecutor {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}
