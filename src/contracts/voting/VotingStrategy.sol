// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseVotingStrategy, IBaseVotingStrategy} from '../BaseVotingStrategy.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {IVotingStrategy, IDataWarehouse} from './interfaces/IVotingStrategy.sol';
import {DelegationMode} from 'aave-token-v3/DelegationAwareBalance.sol';
import {Errors} from '../libraries/Errors.sol';
import {SlotUtils} from '../libraries/SlotUtils.sol';

/**
 * @title VotingStrategy
 * @author BGD Labs
 * @notice This contracts overrides the base voting strategy to return specific assets used on the strategy.
 * @dev These tokens will be used to get the voting power for proposal voting
 */
contract VotingStrategy is BaseVotingStrategy, IVotingStrategy {
  /// @inheritdoc IVotingStrategy
  IDataWarehouse public immutable DATA_WAREHOUSE;

  /// @inheritdoc IVotingStrategy
  uint256 public constant STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION = 1e18;

  /// @inheritdoc IVotingStrategy
  uint256 public constant STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT = 81;

  /// @inheritdoc IVotingStrategy
  uint256 public constant POWER_SCALE_FACTOR = 1e10;

  /**
   * @param dataWarehouse address of the DataWarehouse contract used to store roots
   */
  constructor(address dataWarehouse) BaseVotingStrategy() {
    require(dataWarehouse != address(0), Errors.INVALID_DATA_WAREHOUSE);
    DATA_WAREHOUSE = IDataWarehouse(dataWarehouse);
  }

  /// @inheritdoc IVotingStrategy
  function getVotingPower(
    address asset,
    uint128 storageSlot,
    uint256 power,
    bytes32 blockHash
  ) public view returns (uint256) {
    uint256 votingPower;

    if (asset == STK_AAVE()) {
      if (storageSlot == BASE_BALANCE_SLOT) {
        uint256 slashingExchangeRateSlotValue = DATA_WAREHOUSE
          .getRegisteredSlot(
            blockHash,
            asset,
            bytes32(STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT)
          );

        // casting to uint216 as exchange rate is saved in first 27 bytes of slot
        uint256 slashingExchangeRate = uint256(
          uint216(slashingExchangeRateSlotValue)
        );

        // Shifting to take into account how stk aave token balances is structured
        votingPower = uint72(power >> (104 + 72)) * POWER_SCALE_FACTOR; // stored delegated voting power was scaled down by POWER_SCALE_FACTOR

        DelegationMode delegationMode = DelegationMode(
          uint8(power >> (104 + 72 + 72))
        );

        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          // adding user token balance if is not delegating his voting power
          votingPower += uint104(power);
        }
        // applying slashing exchange rate
        votingPower =
          (votingPower * STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION) /
          slashingExchangeRate;
      }
    } else if (asset == AAVE()) {
      if (storageSlot == BASE_BALANCE_SLOT) {
        // Shifting to take into account how aave token v3 balances is structured
        votingPower = uint72(power >> (104 + 72)) * POWER_SCALE_FACTOR; // stored delegated voting power was scaled down by POWER_SCALE_FACTOR

        DelegationMode delegationMode = DelegationMode(
          uint8(power >> (104 + 72 + 72))
        );

        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          votingPower += uint104(power); // adding user token balance if is not delegating his voting power
        }
      }
    } else if (asset == A_AAVE()) {
      if (storageSlot == A_AAVE_DELEGATED_STATE_SLOT) {
        // Shifting to take into account how aave a token delegation balances is structured
        votingPower = uint72(power >> 72) * POWER_SCALE_FACTOR; // stored delegated voting power was scaled down by POWER_SCALE_FACTOR
      } else if (storageSlot == A_AAVE_BASE_BALANCE_SLOT) {
        // need to get first 120 as its where balance is stored
        uint256 powerBalance = uint256(uint120(power));

        // next uint8 is for delegationMode
        DelegationMode delegationMode = DelegationMode(uint8(power >> (120)));
        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          votingPower += powerBalance; // adding user token balance if is not delegating his voting power
        }
      }
    }

    return votingPower;
  }

  // @inheritdoc IVotingStrategy
  function hasRequiredRoots(bytes32 blockHash) external view {
    require(
      DATA_WAREHOUSE.getStorageRoots(AAVE(), blockHash) != bytes32(0),
      Errors.MISSING_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getStorageRoots(STK_AAVE(), blockHash) != bytes32(0),
      Errors.MISSING_STK_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getStorageRoots(A_AAVE(), blockHash) != bytes32(0),
      Errors.MISSING_A_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getRegisteredSlot(
        blockHash,
        STK_AAVE(),
        bytes32(STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT)
      ) > 0,
      Errors.MISSING_STK_AAVE_SLASHING_EXCHANGE_RATE
    );
  }
}
