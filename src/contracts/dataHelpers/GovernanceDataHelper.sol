// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';
import {IGovernanceDataHelper} from './interfaces/IGovernanceDataHelper.sol';
import {IGovernanceCore} from '../../interfaces/IGovernanceCore.sol';
import {VotingPortal} from '../VotingPortal.sol';

/**
 * @title GovernanceDataHelper
 * @author BGD Labs
 * @notice this contract contains the logic to get the proposals data and to retreive the voting configs.
 */
contract GovernanceDataHelper is IGovernanceDataHelper {
  /// @inheritdoc IGovernanceDataHelper
  function getProposalsData(
    IGovernanceCore govCore,
    uint256 from, // if from is 0 then uses the latest id
    uint256 to, // if to is 0 then will be ignored
    uint256 pageSize
  ) external view returns (Proposal[] memory) {
    if (from == 0) {
      from = govCore.getProposalsCount();
      if (from == 0) {
        return new Proposal[](0);
      }
    } else {
      from += 1;
    }
    require(from >= to, 'from >= to');
    uint256 tempTo = from > pageSize ? from - pageSize : 0;
    if (tempTo > to) {
      to = tempTo;
    }
    pageSize = from - to;
    Proposal[] memory proposals = new Proposal[](pageSize);
    IGovernanceCore.Proposal memory proposalData;

    for (uint256 i = 0; i < pageSize; i++) {
      proposalData = govCore.getProposal(from - i - 1);
      VotingPortal votingPortal = VotingPortal(proposalData.votingPortal);
      proposals[i] = Proposal({
        id: from - i - 1,
        votingChainId: votingPortal.VOTING_MACHINE_CHAIN_ID(),
        proposalData: proposalData
      });
    }

    return proposals;
  }

  /// @inheritdoc IGovernanceDataHelper
  function getConstants(
    IGovernanceCore govCore,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (Constants memory) {
    VotingConfig[] memory votingConfigs = new VotingConfig[](
      accessLevels.length
    );
    IGovernanceCore.VotingConfig memory votingConfig;

    for (uint256 i = 0; i < accessLevels.length; i++) {
      votingConfig = govCore.getVotingConfig(accessLevels[i]);
      votingConfigs[i] = VotingConfig({
        accessLevel: accessLevels[i],
        config: votingConfig
      });
    }

    uint256 precisionDivider = govCore.PRECISION_DIVIDER();
    uint256 cooldownPeriod = govCore.COOLDOWN_PERIOD();
    uint256 expirationTime = govCore.PROPOSAL_EXPIRATION_TIME();

    return
      Constants({
        votingConfigs: votingConfigs,
        precisionDivider: precisionDivider,
        cooldownPeriod: cooldownPeriod,
        expirationTime: expirationTime,
        cancellationFee: govCore.getCancellationFee()
      });
  }

  /// @inheritdoc IGovernanceDataHelper
  function getRepresentationData(
    IGovernanceCore govCore,
    address wallet,
    uint256[] calldata chainIds
  ) external view returns (Representatives[] memory, Represented[] memory) {
    Representatives[] memory representatives = new Representatives[](
      chainIds.length
    );
    Represented[] memory representedVoters = new Represented[](chainIds.length);

    for (uint256 i = 0; i < chainIds.length; i++) {
      representatives[i] = Representatives({
        chainId: chainIds[i],
        representative: govCore.getRepresentativeByChain(wallet, chainIds[i])
      });
      representedVoters[i] = Represented({
        chainId: chainIds[i],
        votersRepresented: govCore.getRepresentedVotersByChain(
          wallet,
          chainIds[i]
        )
      });
    }

    return (representatives, representedVoters);
  }
}
