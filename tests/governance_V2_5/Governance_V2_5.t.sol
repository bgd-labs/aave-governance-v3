// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IGovernance_V2_5, Governance_V2_5, PayloadsControllerUtils} from '../../src/contracts/governance_2_5/Governance_V2_5.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {ITransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';

contract Governance_V2_5_Test is Test {
  IGovernance_V2_5 govV2_5Impl;

  function setUp() public {
    vm.createSelectFork('ethereum', 18376320);

    govV2_5Impl = new Governance_V2_5();

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    ProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      ITransparentUpgradeableProxy(
        payable(address(GovernanceV3Ethereum.GOVERNANCE))
      ),
      address(govV2_5Impl),
      abi.encodeWithSelector(IGovernance_V2_5.initialize.selector)
    );
  }

  function test_initialize() public {
    assertEq(
      IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
        .CROSS_CHAIN_CONTROLLER(),
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER
    );
    assertEq(
      IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE)).GAS_LIMIT(),
      150_000
    );
  }

  function test_forwardPayloadForExecution() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: ChainIds.ETHEREUM,
        payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1
      });

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }

  function test_forwardPayloadForExecution_wrongSender() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: ChainIds.ETHEREUM,
        payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1
      });

    vm.expectRevert(Governance_V2_5.CallerNotShortExecutor.selector);
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }

  function test_forwardPayloadForExecution_wrongAccessLevelNull() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: ChainIds.ETHEREUM,
        payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_null
      });

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOAD_ACCESS_LEVEL));
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }

  function test_forwardPayloadForExecution_wrongAccessLevel2() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: ChainIds.ETHEREUM,
        payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2
      });

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOAD_ACCESS_LEVEL));
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }

  function test_forwardPayloadForExecution_wrongPayloadsController() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: ChainIds.ETHEREUM,
        payloadsController: address(0),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1
      });

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOADS_CONTROLLER));
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }

  function test_forwardPayloadForExecution_wrongChain() public {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        payloadId: uint40(1),
        chain: 0,
        payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1
      });

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOAD_CHAIN));
    IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE))
      .forwardPayloadForExecution(payload);
  }
}
