// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {BaseDelegation} from 'aave-token-v3/BaseDelegation.sol';

contract TokenDelegationTest is Test {
  address public constant AAVE_HOLDER =
    0x3555EF98046FAC600c0B6529E7018EBeCa176398;
  address public constant A_AAVE_HOLDER =
    0xE466d6Cf6E2C3F3f8345d39633d4A968EC879bD5;
  address public constant STK_AAVE_HOLDER =
    0x9bec07CB8E702FA848Cda6A958453455053a016e;

  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address public constant A_AAVE = 0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9;
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  address public constant DELEGATION_RECEIVER = address(123429375);

  uint256 public constant POWER_SCALE_FACTOR = 1e10;

  function setUp() public {
    vm.createSelectFork('ethereum', 18870758);
  }

  function test_DelegateAave() public {
    (uint256 powerBeforeV, uint256 powerBeforeP) = BaseDelegation(AAVE)
      .getPowersCurrent(AAVE_HOLDER);
    hoax(AAVE_HOLDER);
    BaseDelegation(AAVE).delegate(DELEGATION_RECEIVER);

    (uint256 receiverPowerV, uint256 receiverPowerP) = BaseDelegation(AAVE)
      .getPowersCurrent(DELEGATION_RECEIVER);

    assertEq(powerBeforeV, receiverPowerV);
    assertEq(powerBeforeP, receiverPowerP);
  }

  function test_DelegateStkAave() public {
    (uint256 powerBeforeV, uint256 powerBeforeP) = BaseDelegation(STK_AAVE)
      .getPowersCurrent(STK_AAVE_HOLDER);
    hoax(STK_AAVE_HOLDER);
    BaseDelegation(STK_AAVE).delegate(DELEGATION_RECEIVER);

    (uint256 receiverPowerV, uint256 receiverPowerP) = BaseDelegation(STK_AAVE)
      .getPowersCurrent(DELEGATION_RECEIVER);

    assertEq(powerBeforeV, receiverPowerV);
    assertEq(powerBeforeP, receiverPowerP);
  }

  function test_DelegateAAave() public {
    (uint256 powerBeforeV, uint256 powerBeforeP) = BaseDelegation(A_AAVE)
      .getPowersCurrent(A_AAVE_HOLDER);
    hoax(A_AAVE_HOLDER);
    BaseDelegation(A_AAVE).delegate(DELEGATION_RECEIVER);

    (uint256 receiverPowerV, uint256 receiverPowerP) = BaseDelegation(A_AAVE)
      .getPowersCurrent(DELEGATION_RECEIVER);

    assertEq(
      (powerBeforeV / POWER_SCALE_FACTOR) * POWER_SCALE_FACTOR,
      receiverPowerV
    );
    assertEq(
      (powerBeforeP / POWER_SCALE_FACTOR) * POWER_SCALE_FACTOR,
      receiverPowerP
    );
  }
}
