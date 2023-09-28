// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainController} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainController.sol';
import {IVotingMachine, IBaseReceiverPortal, IVotingPortal} from './interfaces/IVotingMachine.sol';
import {VotingMachineWithProofs, IDataWarehouse, IVotingStrategy, IVotingMachineWithProofs} from './VotingMachineWithProofs.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title VotingMachine
 * @author BGD Labs
 * @notice this contract contains the logic to communicate with governance chain.
 * @dev This contract implements the abstract contract VotingMachineWithProofs
 * @dev This contract can receive messages of types Proposal and Vote from governance chain, and send voting results
        back.
 */
contract VotingMachine is VotingMachineWithProofs, IVotingMachine {
  /// @inheritdoc IVotingMachine
  address public immutable CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IVotingMachine
  uint256 public immutable L1_VOTING_PORTAL_CHAIN_ID;

  // address of the L1 VotingPortal contract
  address public immutable L1_VOTING_PORTAL;

  // gas limit used for sending the vote result
  uint256 private _gasLimit;

  /**
   * @param crossChainController address of the CrossChainController contract deployed on current chain. This contract
            is the one responsible to send here the voting configurations once they are bridged.
   * @param gasLimit max number of gas to spend on receiving chain (L1) when sending back the voting results
   * @param l1VotingPortalChainId id of the L1 chain where the voting portal is deployed
   * @param votingStrategy address of the new VotingStrategy contract
   * @param l1VotingPortal address of the L1 Voting Portal contract that communicates with this voting machine
   * @param governance address of the governance contract
   **/
  constructor(
    address crossChainController,
    uint256 gasLimit,
    uint256 l1VotingPortalChainId,
    IVotingStrategy votingStrategy,
    address l1VotingPortal,
    address governance
  ) VotingMachineWithProofs(votingStrategy, governance) {
    require(
      crossChainController != address(0),
      Errors.INVALID_VOTING_MACHINE_CROSS_CHAIN_CONTROLLER
    );
    require(l1VotingPortalChainId > 0, Errors.INVALID_VOTING_PORTAL_CHAIN_ID);
    require(
      l1VotingPortal != address(0),
      Errors.INVALID_VOTING_PORTAL_ADDRESS_IN_VOTING_MACHINE
    );
    CROSS_CHAIN_CONTROLLER = crossChainController;
    L1_VOTING_PORTAL_CHAIN_ID = l1VotingPortalChainId;
    L1_VOTING_PORTAL = l1VotingPortal;

    _updateGasLimit(gasLimit);
  }

  /// @inheritdoc IVotingMachine
  function getGasLimit() external view returns (uint256) {
    return _gasLimit;
  }

  /// @inheritdoc IVotingMachine
  function updateGasLimit(uint256 gasLimit) external onlyOwner {
    _updateGasLimit(gasLimit);
  }

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
    require(
      msg.sender == CROSS_CHAIN_CONTROLLER &&
        originSender == L1_VOTING_PORTAL &&
        originChainId == L1_VOTING_PORTAL_CHAIN_ID,
      Errors.WRONG_MESSAGE_ORIGIN
    );

    try this.decodeMessage(messageWithType) returns (
      IVotingPortal.MessageType messageType,
      bytes memory message
    ) {
      bytes memory empty;
      if (messageType == IVotingPortal.MessageType.Proposal) {
        try this.decodeProposalMessage(message) returns (
          uint256 proposalId,
          bytes32 blockHash,
          uint24 votingDuration
        ) {
          _createBridgedProposalVote(proposalId, blockHash, votingDuration);
          emit MessageReceived(
            originSender,
            originChainId,
            true,
            messageType,
            message,
            empty
          );
        } catch (bytes memory decodingError) {
          emit MessageReceived(
            originSender,
            originChainId,
            false,
            messageType,
            message,
            decodingError
          );
        }
      } else {
        emit IncorrectTypeMessageReceived(
          originSender,
          originChainId,
          messageWithType,
          abi.encodePacked('unsupported message type: ', messageType)
        );
      }
    } catch (bytes memory decodingError) {
      emit IncorrectTypeMessageReceived(
        originSender,
        originChainId,
        messageWithType,
        decodingError
      );
    }
  }

  /// @inheritdoc IVotingMachine
  function decodeVoteMessage(
    bytes memory message
  )
    external
    pure
    returns (uint256, address, bool, VotingAssetWithSlot[] memory)
  {
    return abi.decode(message, (uint256, address, bool, VotingAssetWithSlot[]));
  }

  /// @inheritdoc IVotingMachine
  function decodeProposalMessage(
    bytes memory message
  ) external pure returns (uint256, bytes32, uint24) {
    return abi.decode(message, (uint256, bytes32, uint24));
  }

  /// @inheritdoc IVotingMachine
  function decodeMessage(
    bytes memory message
  ) external pure returns (IVotingPortal.MessageType, bytes memory) {
    return abi.decode(message, (IVotingPortal.MessageType, bytes));
  }

  /**
   * @dev method to send the vote result to the voting portal on governance chain
   * @param proposalId id of the proposal voted on
   * @param forVotes votes in favor of the proposal
   * @param againstVotes votes against the proposal
   */
  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal override {
    ICrossChainController(CROSS_CHAIN_CONTROLLER).forwardMessage(
      L1_VOTING_PORTAL_CHAIN_ID,
      L1_VOTING_PORTAL,
      _gasLimit,
      abi.encode(proposalId, forVotes, againstVotes)
    );
  }

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   */
  function _updateGasLimit(uint256 gasLimit) internal {
    _gasLimit = gasLimit;

    emit GasLimitUpdated(gasLimit);
  }
}
