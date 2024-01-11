// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingPortal} from '../../../interfaces/IVotingPortal.sol';
import {IVotingMachineWithProofs} from './IVotingMachineWithProofs.sol';
import {ICrossChainControllerAdapter} from '../../../interfaces/ICrossChainControllerAdapter.sol';

/**
 * @title IVotingMachine
 * @author BGD Labs
 * @notice interface containing the methods definitions of the VotingMachine contract
 */
interface IVotingMachine is ICrossChainControllerAdapter {
  /**
   * @notice emitted when gas limit gets updated
   * @param gasLimit the new gas limit
   */
  event GasLimitUpdated(uint256 indexed gasLimit);

  /**
   * @notice method to get the chain id of the origin / receiving chain (L1)
   * @return the chainId
   */
  function L1_VOTING_PORTAL_CHAIN_ID() external view returns (uint256);

  /**
   * @notice method to get the VotingPortal of the origin / receiving chain (L1)
   * @return address of the VotingPortal
   */
  function L1_VOTING_PORTAL() external view returns (address);

  /**
   * @notice method to decode a proposal message from from governance chain
   * @param message encoded proposal message
   * @return information to start a proposal vote, including proposalId, blockHash and votingDuration
   */
  function decodeStartProposalVoteMessage(
    bytes memory message
  ) external view returns (uint256, bytes32, uint24);

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   * @dev this method should have a owner gated permission. But responsibility is relegated to inheritance
   */
  function updateGasLimit(uint256 gasLimit) external;

  /**
   * @notice method to get the gasLimit
   * @return gasLimit the new gas limit
   */
  function getGasLimit() external view returns (uint256);
}
