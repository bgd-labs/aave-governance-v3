// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {IGovernanceCore, IGovernancePowerStrategy, PayloadsControllerUtils, EnumerableSet} from '../interfaces/IGovernanceCore.sol';
import {IVotingPortal} from '../interfaces/IVotingPortal.sol';
import {Errors} from './libraries/Errors.sol';
import {IVotingMachineWithProofs} from './voting/interfaces/IVotingMachineWithProofs.sol';
import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';

/**
 * @title GovernanceCore
 * @author BGD Labs
 * @notice this contract contains the logic to create proposals and communicate with the voting machine to vote on the
           proposals and the payloadsController to execute them, being in the same or different network.
 * @dev Abstract contract that is implemented on Governance contract
 * @dev !!!!!!!!!!! CHILD CLASS SHOULD IMPLEMENT initialize() and CALL _initializeCore METHOD FROM THERE !!!!!!!!!!!!
 */
abstract contract GovernanceCore is
  IGovernanceCore,
  Initializable,
  OwnableWithGuardian
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeCast for uint256;

  // @inheritdoc IGovernanceCore
  address public immutable CANCELLATION_FEE_COLLECTOR;

  // @inheritdoc IGovernanceCore
  uint256 public constant PRECISION_DIVIDER = 1 ether;

  // @inheritdoc IGovernanceCore
  uint256 public constant PROPOSAL_EXPIRATION_TIME = 30 days;

  // @inheritdoc IGovernanceCore
  uint256 public immutable COOLDOWN_PERIOD;

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
  mapping(uint256 => Proposal) internal _proposals;

  // (accessLevel => VotingConfig) mapping storing the different voting configurations.
  // Indexed by access level (level 1, level 2)
  mapping(PayloadsControllerUtils.AccessControl => VotingConfig)
    internal _votingConfigs;

  // voter => chainId => representative.
  // Stores the representative of a voter by chain. A representative can vote on behalf of his represented voter
  mapping(address => mapping(uint256 => address)) internal _representatives;

  // representative => chainId => voters
  // set with the represented voters of an address
  mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
    internal _votersRepresented;

  /// @inheritdoc IGovernanceCore
  string public constant NAME = 'Aave Governance v3';

  /**
   * @param coolDownPeriod time that should pass before proposal will be moved to vote, in seconds
   * @param cancellationFeeCollector address of the Aave collector
   */
  constructor(uint256 coolDownPeriod, address cancellationFeeCollector) {
    require(
      cancellationFeeCollector != address(0),
      Errors.INVALID_CANCELLATION_FEE_COLLECTOR
    );
    CANCELLATION_FEE_COLLECTOR = cancellationFeeCollector;
    COOLDOWN_PERIOD = coolDownPeriod;
  }

  // @inheritdoc IGovernanceCore
  function ACHIEVABLE_VOTING_PARTICIPATION()
    public
    view
    virtual
    returns (uint256)
  {
    return 5_000_000 ether;
  }

  // @inheritdoc IGovernanceCore
  function MIN_VOTING_DURATION() public view virtual returns (uint256) {
    return 3 days;
  }

  /**
   * @notice method to initialize governance v3 core
   * @param owner address of the new owner of governance
   * @param guardian address of the new guardian of governance
   * @param powerStrategy address of the governance chain voting strategy
   * @param votingConfigs objects containing the information of different voting configurations depending on access level
   * @param votingPortals objects containing the information of different voting machines depending on chain id
   * @param cancellationFee fee amount to collateralize against proposal cancellation
   */
  function _initializeCore(
    address owner,
    address guardian,
    IGovernancePowerStrategy powerStrategy,
    SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals,
    uint256 cancellationFee
  ) internal initializer {
    require(votingConfigs.length == 2, Errors.MISSING_VOTING_CONFIGURATIONS);
    require(
      votingConfigs[0].accessLevel != votingConfigs[1].accessLevel,
      Errors.INVALID_INITIAL_VOTING_CONFIGS
    );

    _transferOwnership(owner);
    _updateGuardian(guardian);
    _setPowerStrategy(powerStrategy);
    _setVotingConfigs(votingConfigs);
    _updateVotingPortals(votingPortals, true);
    _updateCancellationFee(cancellationFee);
  }

  /// @inheritdoc IGovernanceCore
  function updateCancellationFee(uint256 cancellationFee) external onlyOwner {
    _updateCancellationFee(cancellationFee);
  }

  /// @inheritdoc IGovernanceCore
  function getCancellationFee() external view returns (uint256) {
    return _cancellationFee;
  }

  /// @inheritdoc IGovernanceCore
  function getRepresentedVotersByChain(
    address representative,
    uint256 chainId
  ) external view returns (address[] memory) {
    return _votersRepresented[representative][chainId].values();
  }

  /// @inheritdoc IGovernanceCore
  function getRepresentativeByChain(
    address voter,
    uint256 chainId
  ) external view returns (address) {
    return _representatives[voter][chainId];
  }

  /// @inheritdoc IGovernanceCore
  function updateRepresentativesForChain(
    RepresentativeInput[] calldata representatives
  ) external {
    for (uint256 i = 0; i < representatives.length; i++) {
      uint256 chainId = representatives[i].chainId;
      address newRepresentative = representatives[i].representative !=
        msg.sender
        ? representatives[i].representative
        : address(0);
      address oldRepresentative = _representatives[msg.sender][chainId];

      if (oldRepresentative != address(0)) {
        _votersRepresented[oldRepresentative][chainId].remove(msg.sender);
      }

      if (newRepresentative != address(0)) {
        _votersRepresented[newRepresentative][chainId].add(msg.sender);
      }

      _representatives[msg.sender][chainId] = newRepresentative;

      emit RepresentativeUpdated(msg.sender, newRepresentative, chainId);
    }
  }

  /// @inheritdoc IGovernanceCore
  function getVotingPortalsCount() external view returns (uint256) {
    return _votingPortalsCount;
  }

  /// @inheritdoc IGovernanceCore
  function getPowerStrategy() external view returns (IGovernancePowerStrategy) {
    return _powerStrategy;
  }

  /// @inheritdoc IGovernanceCore
  function getProposalsCount() external view returns (uint256) {
    return _proposalsCount;
  }

  /// @inheritdoc IGovernanceCore
  function isVotingPortalApproved(
    address votingPortal
  ) public view returns (bool) {
    return _votingPortals[votingPortal];
  }

  /// @inheritdoc IGovernanceCore
  function addVotingPortals(
    address[] calldata votingPortals
  ) external onlyOwner {
    _updateVotingPortals(votingPortals, true);
  }

  /// @inheritdoc IGovernanceCore
  function rescueVotingPortal(address votingPortal) external onlyGuardian {
    require(_votingPortalsCount == 0, Errors.VOTING_PORTALS_COUNT_NOT_0);

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = votingPortal;
    _updateVotingPortals(votingPortals, true);
  }

  /// @inheritdoc IGovernanceCore
  function removeVotingPortals(
    address[] calldata votingPortals
  ) external onlyOwner {
    _updateVotingPortals(votingPortals, false);
  }

  /// @inheritdoc IGovernanceCore
  function createProposal(
    PayloadsControllerUtils.Payload[] calldata payloads,
    address votingPortal,
    bytes32 ipfsHash
  ) external payable returns (uint256) {
    require(payloads.length != 0, Errors.AT_LEAST_ONE_PAYLOAD);
    require(ipfsHash != bytes32(0), Errors.G_INVALID_IPFS_HASH);
    require(
      msg.value == _cancellationFee,
      Errors.INVALID_CANCELLATION_FEE_SENT
    );

    require(
      isVotingPortalApproved(votingPortal),
      Errors.VOTING_PORTAL_NOT_APPROVED
    );

    uint256 proposalId = _proposalsCount++;
    Proposal storage proposal = _proposals[proposalId];

    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired;
    for (uint256 i = 0; i < payloads.length; i++) {
      require(
        payloads[i].accessLevel >
          PayloadsControllerUtils.AccessControl.Level_null,
        Errors.G_INVALID_PAYLOAD_ACCESS_LEVEL
      );
      require(
        payloads[i].payloadsController != address(0),
        Errors.G_INVALID_PAYLOADS_CONTROLLER
      );
      require(payloads[i].chain > 0, Errors.G_INVALID_PAYLOAD_CHAIN);
      proposal.payloads.push(payloads[i]);

      if (payloads[i].accessLevel > maximumAccessLevelRequired) {
        maximumAccessLevelRequired = payloads[i].accessLevel;
      }
    }

    VotingConfig memory votingConfig = _votingConfigs[
      maximumAccessLevelRequired
    ];

    address proposalCreator = msg.sender;
    require(
      _isPropositionPowerEnough(
        votingConfig,
        _powerStrategy.getFullPropositionPower(proposalCreator)
      ),
      Errors.PROPOSITION_POWER_IS_TOO_LOW
    );

    proposal.state = State.Created;
    proposal.creator = proposalCreator;
    proposal.accessLevel = maximumAccessLevelRequired;
    proposal.votingPortal = votingPortal;
    proposal.creationTime = uint40(block.timestamp);
    proposal.ipfsHash = ipfsHash;
    proposal.cancellationFee = msg.value;

    emit ProposalCreated(
      proposalId,
      proposalCreator,
      maximumAccessLevelRequired,
      ipfsHash
    );

    return proposalId;
  }

  /// @inheritdoc IGovernanceCore
  function activateVoting(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    VotingConfig memory votingConfig = _votingConfigs[proposal.accessLevel];

    uint40 proposalCreationTime = proposal.creationTime;
    bytes32 blockHash = blockhash(block.number - 1);

    require(
      _getProposalState(proposal) == State.Created,
      Errors.PROPOSAL_NOT_IN_CREATED_STATE
    );

    require(
      isVotingPortalApproved(proposal.votingPortal),
      Errors.VOTING_PORTAL_NOT_APPROVED
    );

    require(
      block.timestamp - proposalCreationTime >
        votingConfig.coolDownBeforeVotingStart,
      Errors.VOTING_START_COOLDOWN_PERIOD_NOT_PASSED
    );

    require(
      _isPropositionPowerEnough(
        votingConfig,
        _powerStrategy.getFullPropositionPower(proposal.creator)
      ),
      Errors.PROPOSITION_POWER_IS_TOO_LOW
    );

    proposal.votingActivationTime = uint40(block.timestamp);
    proposal.snapshotBlockHash = blockHash;
    proposal.state = State.Active;
    proposal.votingDuration = votingConfig.votingDuration;

    IVotingPortal(proposal.votingPortal).forwardStartVotingMessage(
      proposalId,
      blockHash,
      proposal.votingDuration
    );
    emit VotingActivated(proposalId, blockHash, votingConfig.votingDuration);
  }

  /// @inheritdoc IGovernanceCore
  function queueProposal(
    uint256 proposalId,
    uint128 forVotes,
    uint128 againstVotes
  ) external {
    Proposal storage proposal = _proposals[proposalId];
    address votingPortal = proposal.votingPortal;

    // only the accepted portal for this proposal can queue it
    require(
      msg.sender == votingPortal && isVotingPortalApproved(votingPortal),
      Errors.CALLER_NOT_A_VALID_VOTING_PORTAL
    );

    require(
      _getProposalState(proposal) == State.Active,
      Errors.PROPOSAL_NOT_IN_ACTIVE_STATE
    );

    require(
      block.timestamp > proposal.votingDuration + proposal.votingActivationTime,
      Errors.VOTING_DURATION_NOT_PASSED
    );

    VotingConfig memory votingConfig = _votingConfigs[proposal.accessLevel];

    proposal.forVotes = forVotes;
    proposal.againstVotes = againstVotes;

    if (
      _isPropositionPowerEnough(
        votingConfig,
        _powerStrategy.getFullPropositionPower(proposal.creator)
      ) &&
      _isPassingYesThreshold(votingConfig, forVotes) &&
      _isPassingYesNoDifferential(votingConfig, forVotes, againstVotes)
    ) {
      proposal.queuingTime = uint40(block.timestamp);
      proposal.state = State.Queued;
      emit ProposalQueued(proposalId, forVotes, againstVotes);
    } else {
      proposal.state = State.Failed;
      emit ProposalFailed(proposalId, forVotes, againstVotes);
    }
  }

  /// @inheritdoc IGovernanceCore
  function executeProposal(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == State.Queued,
      Errors.PROPOSAL_NOT_IN_QUEUED_STATE
    );
    require(
      block.timestamp >= proposal.queuingTime + COOLDOWN_PERIOD,
      Errors.QUEUE_COOLDOWN_PERIOD_NOT_PASSED
    );
    require(
      _isPropositionPowerEnough(
        _votingConfigs[proposal.accessLevel],
        _powerStrategy.getFullPropositionPower(proposal.creator)
      ),
      Errors.PROPOSITION_POWER_IS_TOO_LOW
    );

    proposal.state = State.Executed;

    for (uint256 i = 0; i < proposal.payloads.length; i++) {
      PayloadsControllerUtils.Payload memory payload = proposal.payloads[i];

      // votingActivationTime is sent to PayloadsController to force that the payload voted on the proposal
      // was registered before the vote happened, ensuring that the voters were able to check the contents
      // of the payload before emitting the vote.
      _forwardPayloadForExecution(payload, proposal.votingActivationTime);
      emit PayloadSent(
        proposalId,
        payload.payloadId,
        payload.payloadsController,
        payload.chain,
        i,
        proposal.payloads.length
      );
    }

    emit ProposalExecuted(proposalId);
  }

  /// @inheritdoc IGovernanceCore
  function cancelProposal(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    State proposalState = _getProposalState(proposal);
    address proposalCreator = proposal.creator;

    require(
      proposalState != State.Null &&
        uint256(proposalState) < uint256(State.Executed),
      Errors.PROPOSAL_NOT_IN_THE_CORRECT_STATE
    );

    if (
      isVotingPortalApproved(proposal.votingPortal) &&
      proposalCreator != msg.sender &&
      _isPropositionPowerEnough(
        _votingConfigs[proposal.accessLevel],
        _powerStrategy.getFullPropositionPower(proposalCreator)
      )
    ) {
      _checkGuardian();
    }

    proposal.state = State.Cancelled;
    proposal.cancelTimestamp = uint40(block.timestamp);
    emit ProposalCanceled(proposalId);
  }

  /// @inheritdoc IGovernanceCore
  function redeemCancellationFee(uint256[] calldata proposalIds) external {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      Proposal storage proposal = _proposals[proposalIds[i]];
      State proposalState = _getProposalState(proposal);

      address to;
      if (proposalState == State.Cancelled) {
        to = CANCELLATION_FEE_COLLECTOR;
      } else if (proposalState >= State.Executed) {
        to = proposal.creator;
      } else {
        revert(Errors.INVALID_STATE_TO_REDEEM_CANCELLATION_FEE);
      }

      uint256 cancellationFee = proposal.cancellationFee;
      require(cancellationFee > 0, Errors.CANCELLATION_FEE_ALREADY_REDEEMED);

      proposal.cancellationFee = 0;

      (bool success, ) = to.call{value: cancellationFee}(new bytes(0));
      require(success, Errors.CANCELLATION_FEE_REDEEM_FAILED);

      emit CancellationFeeRedeemed(
        proposalIds[i],
        to,
        cancellationFee,
        success
      );
    }
  }

  /// @inheritdoc IGovernanceCore
  function getProposalState(uint256 proposalId) external view returns (State) {
    Proposal storage proposal = _proposals[proposalId];

    return _getProposalState(proposal);
  }

  /// @inheritdoc IGovernanceCore
  function setVotingConfigs(
    SetVotingConfigInput[] calldata votingConfigs
  ) external onlyOwner {
    _setVotingConfigs(votingConfigs);
  }

  /// @inheritdoc IGovernanceCore
  function setPowerStrategy(
    IGovernancePowerStrategy powerStrategy
  ) external onlyOwner {
    _setPowerStrategy(powerStrategy);
  }

  /// @inheritdoc IGovernanceCore
  function getProposal(
    uint256 proposalId
  ) external view returns (Proposal memory) {
    Proposal memory proposal = _proposals[proposalId];
    proposal.state = _getProposalState(_proposals[proposalId]);
    return proposal;
  }

  /// @inheritdoc IGovernanceCore
  function getVotingConfig(
    PayloadsControllerUtils.AccessControl accessLevel
  ) external view returns (VotingConfig memory) {
    return _votingConfigs[accessLevel];
  }

  /**
   * @notice method to override that should be in charge of sending payload for execution
   * @param payload object containing the information necessary for execution
   * @param proposalVoteActivationTimestamp proposal vote activation timestamp in seconds
   */
  function _forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload,
    uint40 proposalVoteActivationTimestamp
  ) internal virtual;

  /**
   * @notice method to update the cancellation fee amount
   * @param cancellationFee fee amount for proposal cancellation collateral
   */
  function _updateCancellationFee(uint256 cancellationFee) internal {
    _cancellationFee = cancellationFee;

    emit CancellationFeeUpdated(cancellationFee);
  }

  /**
   * @notice method to set the voting configuration for a determined access level
   * @param votingConfigs object containing configuration for an access level
   */
  function _setVotingConfigs(
    SetVotingConfigInput[] memory votingConfigs
  ) internal {
    require(votingConfigs.length > 0, Errors.INVALID_VOTING_CONFIGS);

    for (uint256 i = 0; i < votingConfigs.length; i++) {
      require(
        votingConfigs[i].accessLevel >
          PayloadsControllerUtils.AccessControl.Level_null,
        Errors.INVALID_VOTING_CONFIG_ACCESS_LEVEL
      );
      require(
        votingConfigs[i].coolDownBeforeVotingStart +
          votingConfigs[i].votingDuration +
          COOLDOWN_PERIOD <
          PROPOSAL_EXPIRATION_TIME,
        Errors.INVALID_VOTING_DURATION
      );
      require(
        votingConfigs[i].votingDuration >= MIN_VOTING_DURATION(),
        Errors.VOTING_DURATION_TOO_SMALL
      );
      require(
        votingConfigs[i].minPropositionPower <=
          ACHIEVABLE_VOTING_PARTICIPATION(),
        Errors.INVALID_PROPOSITION_POWER
      );
      require(
        votingConfigs[i].yesThreshold <= ACHIEVABLE_VOTING_PARTICIPATION(),
        Errors.INVALID_YES_THRESHOLD
      );
      require(
        votingConfigs[i].yesNoDifferential <= ACHIEVABLE_VOTING_PARTICIPATION(),
        Errors.INVALID_YES_NO_DIFFERENTIAL
      );

      VotingConfig memory votingConfig = VotingConfig({
        coolDownBeforeVotingStart: votingConfigs[i].coolDownBeforeVotingStart,
        votingDuration: votingConfigs[i].votingDuration,
        yesThreshold: _normalize(votingConfigs[i].yesThreshold),
        yesNoDifferential: _normalize(votingConfigs[i].yesNoDifferential),
        minPropositionPower: _normalize(votingConfigs[i].minPropositionPower)
      });
      _votingConfigs[votingConfigs[i].accessLevel] = votingConfig;

      emit VotingConfigUpdated(
        votingConfigs[i].accessLevel,
        votingConfig.votingDuration,
        votingConfig.coolDownBeforeVotingStart,
        votingConfig.yesThreshold,
        votingConfig.yesNoDifferential,
        votingConfig.minPropositionPower
      );
    }

    // validation of the voting configs after change, to make it not possible for lvl2 configuration to have configs
    // lower than lvl1
    VotingConfig memory votingConfigL1 = _votingConfigs[
      PayloadsControllerUtils.AccessControl.Level_1
    ];
    VotingConfig memory votingConfigL2 = _votingConfigs[
      PayloadsControllerUtils.AccessControl.Level_2
    ];
    require(
      votingConfigL1.minPropositionPower <= votingConfigL2.minPropositionPower,
      Errors.INVALID_PROPOSITION_POWER
    );
    require(
      votingConfigL1.yesThreshold <= votingConfigL2.yesThreshold,
      Errors.INVALID_YES_THRESHOLD
    );
    require(
      votingConfigL1.yesNoDifferential <= votingConfigL2.yesNoDifferential,
      Errors.INVALID_YES_NO_DIFFERENTIAL
    );
  }

  /**
   * @notice method to set a new _powerStrategy contract
   * @param powerStrategy address of the new contract containing the voting a voting strategy
   */
  function _setPowerStrategy(IGovernancePowerStrategy powerStrategy) internal {
    require(
      address(powerStrategy) != address(0),
      Errors.INVALID_POWER_STRATEGY
    );
    require(
      IBaseVotingStrategy(address(powerStrategy)).getVotingAssetList().length >
        0,
      Errors.POWER_STRATEGY_HAS_NO_TOKENS
    );
    _powerStrategy = powerStrategy;

    emit PowerStrategyUpdated(address(powerStrategy));
  }

  /**
   * @notice method to know if proposition power is bigger than the minimum expected for the voting configuration set
         for this access level
   * @param votingConfig voting configuration from a specific access level, where to check the minimum proposition power
   * @param propositionPower power to check against the voting config minimum
   * @return boolean indicating if power is bigger than minimum
   */
  function _isPropositionPowerEnough(
    IGovernanceCore.VotingConfig memory votingConfig,
    uint256 propositionPower
  ) internal pure returns (bool) {
    return
      propositionPower > votingConfig.minPropositionPower * PRECISION_DIVIDER;
  }

  /**
   * @notice method to know if a vote is passing the yes threshold set in the vote configuration. For this it is required
             for votes to be bigger than configuration yes threshold.
   * @param votingConfig configuration of this voting, set by access level
   * @param forVotes votes in favor of passing the proposal
   * @return boolean indicating the passing of the yes threshold
   */
  function _isPassingYesThreshold(
    VotingConfig memory votingConfig,
    uint256 forVotes
  ) internal pure returns (bool) {
    return forVotes > votingConfig.yesThreshold * PRECISION_DIVIDER;
  }

  /**
   * @notice method to know if the votes pass the yes no differential set by the voting configuration
   * @param votingConfig configuration of this voting, set by access level
   * @param forVotes votes in favor of passing the proposal
   * @param againstVotes votes against passing the proposal
   * @return boolean indicating the passing of the yes no differential
   */
  function _isPassingYesNoDifferential(
    VotingConfig memory votingConfig,
    uint256 forVotes,
    uint256 againstVotes
  ) internal pure returns (bool) {
    return
      forVotes >= againstVotes &&
      forVotes - againstVotes >
      votingConfig.yesNoDifferential * PRECISION_DIVIDER;
  }

  /**
   * @notice method to get the current state of a proposal
   * @param proposal object with all pertinent proposal information
   * @return current state of the proposal
   */
  function _getProposalState(
    Proposal storage proposal
  ) internal view returns (State) {
    State state = proposal.state;
    // small shortcut
    // We can check state >= because we know that Enum state is sequential. If some new State is added / removed check
    // if condition is still valid
    if (
      state == IGovernanceCore.State.Null ||
      state >= IGovernanceCore.State.Executed
    ) {
      return state;
    }

    uint256 expirationTime = proposal.creationTime + PROPOSAL_EXPIRATION_TIME;
    if (
      block.timestamp > expirationTime ||
      (state == IGovernanceCore.State.Created &&
        // if current time + duration of the vote is bigger than expiration time, and vote has not been activated,
        // proposal should be expired as when the vote result returns, proposal will have expired.
        block.timestamp + proposal.votingDuration > expirationTime)
    ) {
      return State.Expired;
    }

    return state;
  }

  /**
   * @notice method to remove specified decimals from a value, as to normalize it.
   * @param value number to remove decimals from
   * @return normalized value
   */
  function _normalize(uint256 value) internal pure returns (uint56) {
    uint256 normalizedValue = value / PRECISION_DIVIDER;
    return normalizedValue.toUint56();
  }

  /**
   * @notice method that approves or disapproves voting machines
   * @param votingPortals list of voting portal addresses
   * @param state boolean indicating if the list is for approval or disapproval of the voting portal addresses
   */
  function _updateVotingPortals(
    address[] memory votingPortals,
    bool state
  ) internal {
    for (uint256 i = 0; i < votingPortals.length; i++) {
      address votingPortal = votingPortals[i];

      require(votingPortal != address(0), Errors.INVALID_VOTING_PORTAL_ADDRESS);
      // if voting portal is already in the target state - just skip
      if (_votingPortals[votingPortal] == state) {
        continue;
      }

      if (state) {
        _votingPortalsCount++;
      } else {
        _votingPortalsCount--;
      }

      _votingPortals[votingPortal] = state;

      emit VotingPortalUpdated(votingPortal, state);
    }
  }
}
