// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IVotingMachine, IVotingPortal} from './interfaces/IVotingMachine.sol';
import {VotingMachineWithProofs, IDataWarehouse, IVotingStrategy, IVotingMachineWithProofs} from './VotingMachineWithProofs.sol';
import {Errors} from '../libraries/Errors.sol';
import {BridgingHelper, CrossChainControllerAdapter} from '../CrossChainControllerAdapter.sol';

/**
 * @title VotingMachine
 * @author BGD Labs
 * @notice this contract contains the logic to communicate with governance chain.
 * @dev This contract implements the abstract contract VotingMachineWithProofs
 * @dev This contract can receive messages of types Proposal and Vote from governance chain, and send voting results
        back.
 */
contract VotingMachine is
  VotingMachineWithProofs,
  CrossChainControllerAdapter,
  IVotingMachine
{
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
  )
    VotingMachineWithProofs(votingStrategy, governance)
    CrossChainControllerAdapter(crossChainController)
  {
    require(l1VotingPortalChainId > 0, Errors.INVALID_VOTING_PORTAL_CHAIN_ID);
    require(
      l1VotingPortal != address(0),
      Errors.INVALID_VOTING_PORTAL_ADDRESS_IN_VOTING_MACHINE
    );
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

  /// @inheritdoc IVotingMachine
  function decodeStartProposalVoteMessage(
    bytes memory message
  ) external pure returns (uint256, bytes32, uint24) {
    return BridgingHelper.decodeStartProposalVoteMessage(message);
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
    bytes memory messageWithType = BridgingHelper.encodeVoteResultsMessage(
      proposalId,
      forVotes,
      againstVotes
    );

    _forwardMessageToCrossChainController(
      L1_VOTING_PORTAL_CHAIN_ID,
      L1_VOTING_PORTAL,
      _gasLimit,
      messageWithType
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

  /// @dev creates a proposal vote
  function _parseReceivedMessage(
    address originSender,
    uint256 originChainId,
    BridgingHelper.MessageType messageType,
    bytes memory message
  ) internal override {
    bytes memory empty;
    if (
      messageType == BridgingHelper.MessageType.Proposal_Vote &&
      originSender == L1_VOTING_PORTAL &&
      originChainId == L1_VOTING_PORTAL_CHAIN_ID
    ) {
      try this.decodeStartProposalVoteMessage(message) returns (
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
        message,
        abi.encode(
          'unsupported message type for origin: ',
          messageType,
          originSender,
          originChainId
        )
      );
    }
  }
}
