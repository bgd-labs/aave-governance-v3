// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingMachineWithProofs, IVotingStrategy, IDataWarehouse} from '../voting/interfaces/IVotingMachineWithProofs.sol';
import {IVotingMachineDataHelper} from './interfaces/IVotingMachineDataHelper.sol';
import {IBaseVotingStrategy} from '../../interfaces/IBaseVotingStrategy.sol';

/**
 * @title PayloadsControllerDataHelper
 * @author BGD Labs
 * @notice this contract contains the logic to get the proposals voting data.
 */
contract VotingMachineDataHelper is IVotingMachineDataHelper {
  /// @inheritdoc IVotingMachineDataHelper
  function getProposalsData(
    IVotingMachineWithProofs votingMachine,
    InitialProposal[] calldata initialProposals,
    address user
  ) external view returns (Proposal[] memory) {
    Proposal[] memory proposals = new Proposal[](initialProposals.length);

    Addresses memory addresses;
    addresses.votingStrategy = votingMachine.VOTING_STRATEGY();
    addresses.dataWarehouse = addresses.votingStrategy.DATA_WAREHOUSE();

    for (uint256 i = 0; i < initialProposals.length; i++) {
      proposals[i].proposalData = votingMachine.getProposalById(
        initialProposals[i].id
      );

      proposals[i].hasRequiredRoots = _hasRequiredRoots(
        votingMachine,
        addresses.votingStrategy,
        initialProposals[i].snapshotBlockHash
      );
      proposals[i].voteConfig = votingMachine.getProposalVoteConfiguration(
        initialProposals[i].id
      );

      proposals[i].strategy = addresses.votingStrategy;
      proposals[i].dataWarehouse = addresses.dataWarehouse;
      proposals[i].votingAssets = IBaseVotingStrategy(
        address(addresses.votingStrategy)
      ).getVotingAssetList();

      proposals[i].state = votingMachine.getProposalState(
        initialProposals[i].id
      );

      if (user != address(0)) {
        // direct vote
        IVotingMachineWithProofs.Vote memory vote = votingMachine
          .getUserProposalVote(user, initialProposals[i].id);

        proposals[i].votedInfo = VotedInfo({
          support: vote.support,
          votingPower: vote.votingPower
        });
      }
    }

    return proposals;
  }

  function _hasRequiredRoots(
    IVotingMachineWithProofs votingMachine,
    IVotingStrategy votingStrategy,
    bytes32 snapshotBlockHash
  ) internal view returns (bool) {
    bool hasRequiredRoots;
    try votingStrategy.hasRequiredRoots(snapshotBlockHash) {
      hasRequiredRoots = true;
    } catch (bytes memory) {}

    bytes32 repRoots = votingStrategy.DATA_WAREHOUSE().getStorageRoots(
      votingMachine.GOVERNANCE(),
      snapshotBlockHash
    );

    return hasRequiredRoots && repRoots != bytes32(0);
  }
}
