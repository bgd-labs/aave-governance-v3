// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';
import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';
import {IGovernancePowerStrategy} from '../../interfaces/IGovernancePowerStrategy.sol';
import {IGovernance_V2_5, PayloadsControllerUtils} from './IGovernance_V2_5.sol';
import {IGovernanceCore} from '../../interfaces/IGovernanceCore.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';

/**
 * @title Governance V2.5
 * @author BGD Labs
 * @notice this contract contains the logic to relay payload execution message to the governance v3 payloadsController
           to execute a payload registered there, on the same or different network.
 */
contract Governance_V2_5 is
  IGovernance_V2_5,
  Initializable,
  OwnableWithGuardian
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeCast for uint256;

  /// @inheritdoc IGovernance_V2_5
  address public constant CROSS_CHAIN_CONTROLLER =
    0xEd42a7D8559a463722Ca4beD50E0Cc05a386b0e1;

  /// --------------------------------------- V3 STORAGE LAYOUT ---------------------------------------------------- ///

  IGovernancePowerStrategy internal _powerStrategy;

  uint256 internal _proposalsCount;

  // Fee taken as cancellation insurance to protect against spam attacks.
  // If the proposal gets cancelled, this will be sent to the Aave Collector, if not,
  // the proposal creator can claim it back
  uint256 internal _cancellationFee;

  // (votingPortal => approved) mapping to store the approved voting portals
  mapping(address => bool) internal _votingPortals;

  // counts the currently active voting portals
  uint256 internal _votingPortalsCount;

  // (proposalId => Proposal) mapping to store the information of a proposal. indexed by proposalId
  mapping(uint256 => IGovernanceCore.Proposal) internal _proposals;

  // (accessLevel => VotingConfig) mapping storing the different voting configurations.
  // Indexed by access level (level 1, level 2)
  mapping(PayloadsControllerUtils.AccessControl => IGovernanceCore.VotingConfig)
    internal _votingConfigs;

  // voter => chainId => representative.
  // Stores the representative of a voter by chain. A representative can vote on behalf of his represented voter
  mapping(address => mapping(uint256 => address)) internal _representatives;

  // representative => chainId => voters
  // set with the represented voters of an address
  mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
    internal _votersRepresented;

  /// @inheritdoc IGovernance_V2_5
  string public constant NAME = 'Aave Governance v2.5';

  // gas limit used for sending the vote result
  uint256 private _gasLimit;

  /// --------------------------------------- END OF V3 STORAGE LAYOUT --------------------------------------------- ///

  /// @inheritdoc IGovernance_V2_5
  function initialize(address owner) external {
    _transferOwnership(owner);
  }

  /// @inheritdoc IGovernance_V2_5
  function getGasLimit() external view returns (uint256) {
    return _gasLimit;
  }

  /// @inheritdoc IGovernance_V2_5
  function updateGasLimit(uint256 gasLimit) external onlyOwner {
    _updateGasLimit(gasLimit);
  }

  /// @inheritdoc IGovernance_V2_5
  function forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload
  ) external onlyOwner {
    ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).forwardMessage(
      payload.chain,
      payload.payloadsController,
      _gasLimit,
      abi.encode(
        payload.payloadId,
        payload.accessLevel,
        uint40(block.timestamp)
      )
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
