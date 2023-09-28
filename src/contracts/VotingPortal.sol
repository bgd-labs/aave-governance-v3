// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {ICrossChainController} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainController.sol';
import {IGovernanceCore} from '../interfaces/IGovernanceCore.sol';
import {IVotingPortal, IBaseReceiverPortal} from '../interfaces/IVotingPortal.sol';
import {Errors} from './libraries/Errors.sol';
import {IVotingMachineWithProofs} from './voting/interfaces/IVotingMachineWithProofs.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title VotingPortal
 * @author BGD Labs
 * @notice Contract with the knowledge on how to initialize a proposal voting and get the votes results,
           from a vote that happened on a different or same chain.
 */
contract VotingPortal is Ownable, IVotingPortal {
  /// @inheritdoc IVotingPortal
  address public immutable CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IVotingPortal
  address public immutable GOVERNANCE;

  /// @inheritdoc IVotingPortal
  address public immutable VOTING_MACHINE;

  /// @inheritdoc IVotingPortal
  uint256 public immutable VOTING_MACHINE_CHAIN_ID;

  // stores the gas limit for start voting bridging tx
  uint128 internal _startVotingGasLimit;

  // proposalId => voter => has voted  -> saves the voters of every proposal that used this voting portal to send the vote
  mapping(uint256 => mapping(address => bool)) internal _proposalVoters;

  /**
   * @param crossChainController address of current network message controller (cross chain controller or same chain controller)
   * @param governance address of the linked governance contract
   * @param votingMachine address where the proposal votes will happen. Can be same or different chain
   * @param startVotingGasLimit gas limit for "Start voting" bridging tx
   */
  constructor(
    address crossChainController,
    address governance,
    address votingMachine,
    uint256 votingMachineChainId,
    uint128 startVotingGasLimit,
    address owner
  ) {
    require(owner != address(0), Errors.INVALID_VOTING_PORTAL_OWNER);
    require(
      crossChainController != address(0),
      Errors.INVALID_VOTING_PORTAL_CROSS_CHAIN_CONTROLLER
    );
    require(governance != address(0), Errors.INVALID_VOTING_PORTAL_GOVERNANCE);
    require(
      votingMachine != address(0),
      Errors.INVALID_VOTING_PORTAL_VOTING_MACHINE
    );
    require(votingMachineChainId > 0, Errors.INVALID_VOTING_MACHINE_CHAIN_ID);
    CROSS_CHAIN_CONTROLLER = crossChainController;
    GOVERNANCE = governance;
    VOTING_MACHINE = votingMachine;
    VOTING_MACHINE_CHAIN_ID = votingMachineChainId;

    _updateStartVotingGasLimit(startVotingGasLimit);

    _transferOwnership(owner);
  }

  /// @inheritdoc IBaseReceiverPortal
  /// @dev pushes the voting result and queues the proposal identified by proposalId
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == CROSS_CHAIN_CONTROLLER &&
        originSender == VOTING_MACHINE &&
        originChainId == VOTING_MACHINE_CHAIN_ID,
      Errors.WRONG_MESSAGE_ORIGIN
    );

    try this.decodeMessage(message) returns (
      uint256 proposalId,
      uint128 forVotes,
      uint128 againstVotes
    ) {
      IGovernanceCore(GOVERNANCE).queueProposal(
        proposalId,
        forVotes,
        againstVotes
      );

      bytes memory empty;
      emit VoteMessageReceived(
        originSender,
        originChainId,
        true,
        message,
        empty
      );
    } catch (bytes memory decodingError) {
      emit VoteMessageReceived(
        originSender,
        originChainId,
        false,
        message,
        decodingError
      );
    }
  }

  /// @inheritdoc IVotingPortal
  function forwardStartVotingMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);
    _sendMessage(
      msg.sender,
      MessageType.Proposal,
      getStartVotingGasLimit(),
      message
    );
  }

  /// @inheritdoc IVotingPortal
  function decodeMessage(
    bytes memory message
  ) external pure returns (uint256, uint128, uint128) {
    return abi.decode(message, (uint256, uint128, uint128));
  }

  /// @inheritdoc IVotingPortal
  function setStartVotingGasLimit(uint128 gasLimit) external onlyOwner {
    _updateStartVotingGasLimit(gasLimit);
  }

  /// @inheritdoc IVotingPortal
  function getStartVotingGasLimit() public view returns (uint128) {
    return _startVotingGasLimit;
  }

  function _sendMessage(
    address caller,
    MessageType messageType,
    uint256 gasLimit,
    bytes memory message
  ) internal {
    require(caller == GOVERNANCE, Errors.CALLER_NOT_GOVERNANCE);
    bytes memory messageWithType = abi.encode(messageType, message);

    ICrossChainController(CROSS_CHAIN_CONTROLLER).forwardMessage(
      VOTING_MACHINE_CHAIN_ID,
      VOTING_MACHINE,
      gasLimit,
      messageWithType
    );
  }

  /**
   * @notice method to update the _startVotingGasLimit
   * @param gasLimit the new gas limit
   */
  function _updateStartVotingGasLimit(uint128 gasLimit) internal {
    _startVotingGasLimit = gasLimit;
    emit StartVotingGasLimitUpdated(gasLimit);
  }
}
