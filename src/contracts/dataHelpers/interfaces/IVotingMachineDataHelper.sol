// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../../../interfaces/IBaseVotingStrategy.sol';
import {IVotingMachineWithProofs, IVotingStrategy, IDataWarehouse} from '../../voting/interfaces/IVotingMachineWithProofs.sol';

/**
 * @title IVotingMachineDataHelper
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the VotingMachineDataHelper contract
 */
interface IVotingMachineDataHelper {
  /**
   * @notice Object storing addresses
   * @param votingStrategy address of the voting strategy
   * @param dataWarehouse address of the data warehouse
   */
  struct Addresses {
    IVotingStrategy votingStrategy;
    IDataWarehouse dataWarehouse;
  }

  /**
   * @notice Object storing the vote info
   * @param support yes/no
   * @param votingPower power of the vote
   */
  struct VotedInfo {
    bool support;
    uint248 votingPower;
  }

  /**
   * @notice Object storing the proposal
   * @param proposalData if the vote is bridged
   * @param votedInfo vote info
   * @param votingAssets list of the voting assets
   * @param hasRequiredRoots if required roots are presented
   * @param voteConfig configuration for the proposal vote
   * @param state current proposal state
   */
  struct Proposal {
    IVotingMachineWithProofs.ProposalWithoutVotes proposalData;
    VotedInfo votedInfo;
    IVotingStrategy strategy;
    IDataWarehouse dataWarehouse;
    address[] votingAssets;
    bool hasRequiredRoots;
    IVotingMachineWithProofs.ProposalVoteConfiguration voteConfig;
    IVotingMachineWithProofs.ProposalState state;
  }

  /**
   * @notice Object storing the info about initial proposal
   * @param id identifier of the proposal
   * @param snapshotBlockHash hash of the block when the proposal was created
   */
  struct InitialProposal {
    uint256 id;
    bytes32 snapshotBlockHash;
  }

  /**
   * @notice method to get proposals vote info
   * @param votingMachine instance of the voting machine
   * @param initialProposals list of the proposals to get
   * @return list of the proposals with vote info
   */
  function getProposalsData(
    IVotingMachineWithProofs votingMachine,
    InitialProposal[] calldata initialProposals,
    address user
  ) external view returns (Proposal[] memory);
}
