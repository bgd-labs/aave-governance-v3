// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {PayloadsController} from '../../src/contracts/payloads/PayloadsController.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {MiscGnosis} from 'aave-address-book/MiscGnosis.sol';
import {MiscMetis} from 'aave-address-book/MiscMetis.sol';
import {GovernanceV3Ethereum, GovernanceV3Polygon, GovernanceV3Avalanche, GovernanceV3Arbitrum, GovernanceV3Optimism, GovernanceV3Base, GovernanceV3Metis, GovernanceV3Gnosis, GovernanceV3BNB, AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';

contract MockImplementation is Initializable {
  uint256 public constant TEST = 1;

  function initialize() external reinitializer(2) {}
}

abstract contract BaseTest is Test {
  MockImplementation pcImpl;

  function payloadsController() public view virtual returns (address);

  function proxyAdmin() public view virtual returns (address);

  function executorLvl1() public view virtual returns (address);

  function shortExecutor() public view virtual returns (address);

  function _setUp() internal {
    pcImpl = new MockImplementation();

    // update owner of proxyAdmin
    hoax(shortExecutor());
    Ownable(proxyAdmin()).transferOwnership(executorLvl1());

    hoax(executorLvl1());
    ProxyAdmin(proxyAdmin()).upgradeAndCall(
      TransparentUpgradeableProxy(payable(payloadsController())),
      address(pcImpl),
      abi.encodeWithSelector(MockImplementation.initialize.selector)
    );
  }

  function test_ImplementationUpdate() public {
    assertEq(MockImplementation(payloadsController()).TEST(), 1);
  }
}

contract ProxyAdminTestEthereum is BaseTest {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscEthereum.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Ethereum.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }

  function setUp() public {
    vm.createSelectFork('ethereum', 18427147);
    _setUp();
  }
}

contract ProxyAdminTestPolygon is BaseTest {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Polygon.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscPolygon.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Polygon.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR;
  }

  function setUp() public {
    vm.createSelectFork('polygon', 49131391);
    _setUp();
  }
}
