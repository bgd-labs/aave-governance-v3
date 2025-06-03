// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './GovBaseScript.sol';

abstract contract BaseInitialDeployment is GovBaseScript {
  function OWNER() public virtual returns (address) {
    return address(msg.sender); // as first owner we set deployer, this way its easier to configure
  }

  function GUARDIAN() public virtual returns (address) {
    return address(msg.sender);
  }

  function CREATE3_FACTORY() public view virtual returns (address) {
    CCCAddresses memory ccAddresses = _getCCAddresses(TRANSACTION_NETWORK());
    return ccAddresses.create3Factory;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    //    addresses.create3Factory = CREATE3_FACTORY() == address(0)
    //      ? address(new Create3Factory{salt: Constants.CREATE3_FACTORY_SALT}())
    //      : CREATE3_FACTORY();
    addresses.chainId = TRANSACTION_NETWORK();
    addresses.owner = OWNER();
    addresses.guardian = GUARDIAN();
  }
}

contract Ethereum is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Avalanche is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xa35b76E4935449E33C56aB24b23fcd3246f13470;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Optimism is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xE50c8C619d05ff98b22Adf991F17602C774F785c;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xF6Db48C5968A9eBCB935786435530f28e32Cc501;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xF6Db48C5968A9eBCB935786435530f28e32Cc501;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Base is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0x9e10C0A1Eb8FF6a0AaA53a62C7a338f35D7D9a2A;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Gnosis is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0xF163b8698821cefbD33Cf449764d69Ea445cE23D;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0x8C05474F1f0161F71276677De0a2d8a347583c45;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Scroll is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return 0x63B20270b695E44Ac94Ad7592D5f81E3575b93e7;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Zksync is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Linea is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.LINEA;
  }
}

contract Celo is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }
}

contract Sonic is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONIC;
  }
}

contract Mantle is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }
}

contract Ink is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.INK;
  }
}

contract Soneium is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONEIUM;
  }
}

contract Bob is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BOB;
  }
}

contract Ethereum_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Polygon_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Avalanche_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Arbitrum_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_SEPOLIA;
  }
}

contract Optimism_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_SEPOLIA;
  }
}

contract Metis_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Base_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BASE_SEPOLIA;
  }
}

contract Zksync_testnet is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZKSYNC_SEPOLIA;
  }
}
