// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../../payloads/PayloadsControllerUtils.sol';
import {IGovernanceCore} from '../../../interfaces/IGovernanceCore.sol';

/**
 * @title IGovernanceDataHelper
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the GovernanceDataHelper contract
 */
interface IGovernanceDataHelper {
  /**
   * @notice object containing representative for chainId
   * @param chainId id of the chain to get the representative from
   * @param representative address that represents a voter
   */
  struct Representatives {
    uint256 chainId;
    address representative;
  }

  /**
   * @notice object containing the represented voters
   * @param chainId id of the chain to get the represented voters from
   * @param votersRepresented array of addresses of the voters that are represented
   */
  struct Represented {
    uint256 chainId;
    address[] votersRepresented;
  }

  /**
   * @notice object containing proposal information
   * @param id numeric id of a proposal
   * @param votingChainId id of the chain where the proposal is voted on
   * @param proposalData full data of the proposal
   */
  struct Proposal {
    uint256 id;
    uint256 votingChainId;
    IGovernanceCore.Proposal proposalData;
  }

  /**
   * @notice Object storing the vote configuration for a specific access level
   * @param accessLevel access level of the configuration
   * @param config voting configuration
   */
  struct VotingConfig {
    PayloadsControllerUtils.AccessControl accessLevel;
    IGovernanceCore.VotingConfig config;
  }

  /**
   * @notice Object storing the vote configuration for a specific access level
   * @param votingConfigs voting configuration
   * @param precisionDivider internal precision
   * @param cooldownPeriod time in seconds between proposal creation and start of voting
   * @param expirationTime time in seconds when proposal will be expired
   * @param cancellationFee amount to pay governance if proposal gets cancelled
   */
  struct Constants {
    VotingConfig[] votingConfigs;
    uint256 precisionDivider;
    uint256 cooldownPeriod;
    uint256 expirationTime;
    uint256 cancellationFee;
  }

  /**
   * @notice Method to get the representation data of a wallet for a chain
   * @param govCore instance of the governance contract
   * @param wallet address to get the representation data from
   * @param chainIds array of ids of the chain to get the representation data from
   * @return array of representative by chain, array of voters represented by chain
   */
  function getRepresentationData(
    IGovernanceCore govCore,
    address wallet,
    uint256[] calldata chainIds
  ) external view returns (Representatives[] memory, Represented[] memory);

  /**
   * @notice method to get proposals list
   * @param govCore instance of the governance contract
   * @param from proposal number to start fetching from
   * @param to proposal number to end fetching
   * @param pageSize size of the page to get
   * @return list of the proposals
   */
  function getProposalsData(
    IGovernanceCore govCore,
    uint256 from,
    uint256 to,
    uint256 pageSize
  ) external view returns (Proposal[] memory);

  /**
   * @notice method to get voting config and governance setup constants
   * @param govCore instance of the governance contract
   * @param accessLevels list of the access levels to retrieve voting configs for
   * @return list of the voting configs and values of the governance constants
   */
  function getConstants(
    IGovernanceCore govCore,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (Constants memory);
}
