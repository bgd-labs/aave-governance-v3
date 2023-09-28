// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from 'aave-delivery-infrastructure/contracts/interfaces/IBaseReceiverPortal.sol';
import {IVotingPortal} from '../../../interfaces/IVotingPortal.sol';
import {IVotingMachineWithProofs} from './IVotingMachineWithProofs.sol';

/**
 * @title IVotingMachine
 * @author BGD Labs
 * @notice interface containing the methods definitions of the VotingMachine contract
 */
interface IVotingMachine is IBaseReceiverPortal {
  /**
   * @notice emitted when gas limit gets updated
   * @param gasLimit the new gas limit
   */
  event GasLimitUpdated(uint256 indexed gasLimit);

  /**
   * @notice emitted when a cross chain message gets received
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param delivered flag indicating if message has been delivered
   * @param messageType type of the received message
   * @param message bytes containing the necessary information of a user vote
   * @param reason bytes with the revert information
   */
  event MessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    IVotingPortal.MessageType messageType,
    bytes message,
    bytes reason
  );

  /**
   * @notice emitted when a cross chain message does not have the correct type for voting machine
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param message bytes containing the necessary information of a proposal vote
   * @param reason bytes with the revert information
   */
  event IncorrectTypeMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bytes message,
    bytes reason
  );

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
   * @notice method to get the address of the CrossChainController contract deployed on current chain
   * @return the CrossChainController contract address
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice method to decode a message from from governance chain
   * @param message encoded message with message type
   * @return messageType and governance underlying message
   */
  function decodeMessage(
    bytes memory message
  ) external view returns (IVotingPortal.MessageType, bytes memory);

  /**
   * @notice method to decode a vote message
   * @param message encoded vote message
   * @return information to vote on a proposal, including proposalId, voter, support, votingTokens
   */
  function decodeVoteMessage(
    bytes memory message
  )
    external
    view
    returns (
      uint256,
      address,
      bool,
      IVotingMachineWithProofs.VotingAssetWithSlot[] memory
    );

  /**
   * @notice method to decode a proposal message from from governance chain
   * @param message encoded proposal message
   * @return information to start a proposal vote, including proposalId, blockHash and votingDuration
   */
  function decodeProposalMessage(
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
