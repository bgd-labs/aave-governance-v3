// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovernancePowerStrategy} from '../src/contracts/GovernancePowerStrategy.sol';
import {IBaseVotingStrategy} from '../src/interfaces/IBaseVotingStrategy.sol';
import {IGovernancePowerDelegationToken} from '../src/contracts/dataHelpers/interfaces/IGovernancePowerDelegationToken.sol';

contract GovernancePowerStrategyTest is Test {
  address public AAVE;
  address public STK_AAVE;
  address public A_AAVE;
  uint128 public BASE_STORAGE_SLOT;
  uint128 public A_AAVE_BASE_BALANCE_SLOT;
  uint128 public A_AAVE_DELEGATED_STATE_SLOT;

  GovernancePowerStrategy public governancePowerStrategy;

  event VotingAssetAdd(address indexed asset, uint128[] storageSlots);

  function setUp() public {
    governancePowerStrategy = new GovernancePowerStrategy();

    AAVE = IBaseVotingStrategy(address(governancePowerStrategy)).AAVE();
    STK_AAVE = IBaseVotingStrategy(address(governancePowerStrategy)).STK_AAVE();
    A_AAVE = IBaseVotingStrategy(address(governancePowerStrategy)).A_AAVE();
    BASE_STORAGE_SLOT = IBaseVotingStrategy(address(governancePowerStrategy))
      .BASE_BALANCE_SLOT();
    A_AAVE_BASE_BALANCE_SLOT = IBaseVotingStrategy(
      address(governancePowerStrategy)
    ).A_AAVE_BASE_BALANCE_SLOT();
    A_AAVE_DELEGATED_STATE_SLOT = IBaseVotingStrategy(
      address(governancePowerStrategy)
    ).A_AAVE_DELEGATED_STATE_SLOT();
  }

  function testConstructor() public {
    uint128[] memory storageSlots = new uint128[](1);
    storageSlots[0] = BASE_STORAGE_SLOT;

    uint128[] memory storageSlotsAAve = new uint128[](2);
    storageSlotsAAve[0] = A_AAVE_BASE_BALANCE_SLOT;
    storageSlotsAAve[1] = A_AAVE_DELEGATED_STATE_SLOT;

    vm.expectEmit(true, false, false, true);
    emit VotingAssetAdd(AAVE, storageSlots);
    vm.expectEmit(true, false, false, true);
    emit VotingAssetAdd(STK_AAVE, storageSlots);
    vm.expectEmit(true, false, false, true);
    emit VotingAssetAdd(A_AAVE, storageSlotsAAve);
    governancePowerStrategy = new GovernancePowerStrategy();
  }

  function testSetUp(address randomToken) public {
    vm.assume(
      randomToken != AAVE && randomToken != STK_AAVE && randomToken != A_AAVE
    );

    address[] memory tokenList = IBaseVotingStrategy(governancePowerStrategy)
      .getVotingAssetList();
    for (uint256 i; i < tokenList.length; i++) {
      assertEq(tokenList[i] == randomToken, false);
    }
  }

  function testGetVotingAssetList() public {
    address[] memory votingAssets = governancePowerStrategy
      .getVotingAssetList();

    assertEq(votingAssets[0], AAVE);
    assertEq(votingAssets[1], STK_AAVE);
  }

  function testGetVotingAssetConfig() public {
    IBaseVotingStrategy.VotingAssetConfig
      memory votingAssetConfigAave = governancePowerStrategy
        .getVotingAssetConfig(AAVE);

    assertEq(votingAssetConfigAave.storageSlots[0], uint128(0));

    IBaseVotingStrategy.VotingAssetConfig
      memory votingAssetConfigStk = governancePowerStrategy
        .getVotingAssetConfig(STK_AAVE);

    assertEq(votingAssetConfigStk.storageSlots[0], uint128(0));

    address notAsset = address(1);
    IBaseVotingStrategy.VotingAssetConfig
      memory votingAssetConfigNull = governancePowerStrategy
        .getVotingAssetConfig(notAsset);

    assertEq(votingAssetConfigNull.storageSlots.length, 0);
  }

  function testGetFullVotingPower() public {
    address user = address(2134);
    uint256 aavePower = 123;
    uint256 aAavePower = 13;
    uint256 stkAavePower = 3;

    vm.mockCall(
      AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(aavePower)
    );
    vm.expectCall(
      AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        0
      )
    );
    vm.mockCall(
      A_AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(aAavePower)
    );
    vm.expectCall(
      A_AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        0
      )
    );
    vm.mockCall(
      STK_AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(stkAavePower)
    );
    vm.expectCall(
      STK_AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        0
      )
    );

    uint256 fullPower = governancePowerStrategy.getFullVotingPower(user);

    assertEq(fullPower, aavePower + stkAavePower + aAavePower);
  }

  function testGetFullPropositionPower() public {
    address user = address(2134);
    uint256 aavePower = 123;
    uint256 aAavePower = 12;
    uint256 stkAavePower = 3;

    vm.mockCall(
      AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(aavePower)
    );
    vm.expectCall(
      AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        1
      )
    );
    vm.mockCall(
      A_AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(aAavePower)
    );
    vm.expectCall(
      A_AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        1
      )
    );
    vm.mockCall(
      STK_AAVE,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector
      ),
      abi.encode(stkAavePower)
    );
    vm.expectCall(
      STK_AAVE,
      0,
      abi.encodeWithSelector(
        IGovernancePowerDelegationToken.getPowerCurrent.selector,
        user,
        1
      )
    );

    uint256 fullPower = governancePowerStrategy.getFullPropositionPower(user);

    assertEq(fullPower, aavePower + stkAavePower + aAavePower);
  }
}
