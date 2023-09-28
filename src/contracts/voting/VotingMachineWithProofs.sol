// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {IVotingMachineWithProofs, IDataWarehouse, IVotingStrategy} from './interfaces/IVotingMachineWithProofs.sol';
import {IBaseVotingStrategy} from '../../interfaces/IBaseVotingStrategy.sol';
import {Errors} from '../libraries/Errors.sol';
import {SlotUtils} from '../libraries/SlotUtils.sol';
import {EIP712} from 'openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title VotingMachineWithProofs
 * @author BGD Labs
 * @notice this contract contains the logic to vote on a bridged proposal. It uses registered proofs to calculate the
           voting power of the users. Once the voting is finished it will send the results back to the governance chain.
 * @dev Abstract contract that is implemented on VotingMachine contract
 */
abstract contract VotingMachineWithProofs is
  IVotingMachineWithProofs,
  EIP712,
  Ownable
{
  using SafeCast for uint256;

  /// @inheritdoc IVotingMachineWithProofs
  uint256 public constant REPRESENTATIVES_SLOT = 9;

  /// @inheritdoc IVotingMachineWithProofs
  string public constant VOTING_ASSET_WITH_SLOT_RAW =
    'VotingAssetWithSlot(address underlyingAsset,uint128 slot)';

  /// @inheritdoc IVotingMachineWithProofs
  bytes32 public constant VOTE_SUBMITTED_TYPEHASH =
    keccak256(
      abi.encodePacked(
        'SubmitVote(uint256 proposalId,address voter,bool support,VotingAssetWithSlot[] votingAssetsWithSlot)',
        VOTING_ASSET_WITH_SLOT_RAW
      )
    );

  /// @inheritdoc IVotingMachineWithProofs
  bytes32 public constant VOTE_SUBMITTED_BY_REPRESENTATIVE_TYPEHASH =
    keccak256(
      abi.encodePacked(
        'SubmitVoteAsRepresentative(uint256 proposalId,address voter,address representative,bool support,VotingAssetWithSlot[] votingAssetsWithSlot)',
        VOTING_ASSET_WITH_SLOT_RAW
      )
    );

  /// @inheritdoc IVotingMachineWithProofs
  bytes32 public constant VOTING_ASSET_WITH_SLOT_TYPEHASH =
    keccak256(abi.encodePacked(VOTING_ASSET_WITH_SLOT_RAW));

  /// @inheritdoc IVotingMachineWithProofs
  string public constant NAME = 'Aave Voting Machine';

  /// @inheritdoc IVotingMachineWithProofs
  IVotingStrategy public immutable VOTING_STRATEGY;

  /// @inheritdoc IVotingMachineWithProofs
  IDataWarehouse public immutable DATA_WAREHOUSE;

  /// @inheritdoc IVotingMachineWithProofs
  address public immutable GOVERNANCE;

  // (proposalId => proposal information) stores the information of the proposals
  mapping(uint256 => Proposal) internal _proposals;

  // (proposalId => proposal vote configuration) stores the configuration for voting on each proposal
  mapping(uint256 => ProposalVoteConfiguration)
    internal _proposalsVoteConfiguration;

  // saves the ids of the proposals that have been bridged for a vote.
  uint256[] internal _proposalsVoteConfigurationIds;

  /**
   * @param votingStrategy address of the new VotingStrategy contract
   * @param governance address of the governance contract on ethereum
   */
  constructor(
    IVotingStrategy votingStrategy,
    address governance
  ) Ownable() EIP712(NAME, 'V1') {
    require(
      address(votingStrategy) != address(0),
      Errors.INVALID_VOTING_STRATEGY
    );
    require(governance != address(0), Errors.VM_INVALID_GOVERNANCE_ADDRESS);
    VOTING_STRATEGY = votingStrategy;
    DATA_WAREHOUSE = votingStrategy.DATA_WAREHOUSE();
    GOVERNANCE = governance;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalVoteConfiguration(
    uint256 proposalId
  ) external view returns (ProposalVoteConfiguration memory) {
    return _proposalsVoteConfiguration[proposalId];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function startProposalVote(uint256 proposalId) external returns (uint256) {
    ProposalVoteConfiguration memory voteConfig = _proposalsVoteConfiguration[
      proposalId
    ];
    require(
      voteConfig.l1ProposalBlockHash != bytes32(0),
      Errors.MISSING_PROPOSAL_BLOCK_HASH
    );
    Proposal storage newProposal = _proposals[proposalId];

    require(
      _getProposalState(newProposal) == ProposalState.NotCreated,
      Errors.PROPOSAL_VOTE_ALREADY_CREATED
    );

    VOTING_STRATEGY.hasRequiredRoots(voteConfig.l1ProposalBlockHash);

    _checkRepresentationRoots(voteConfig.l1ProposalBlockHash);

    uint40 startTime = _getCurrentTimeRef();
    uint40 endTime = startTime + voteConfig.votingDuration;

    newProposal.id = proposalId;
    newProposal.creationBlockNumber = block.number;
    newProposal.startTime = startTime;
    newProposal.endTime = endTime;

    emit ProposalVoteStarted(
      proposalId,
      voteConfig.l1ProposalBlockHash,
      startTime,
      endTime
    );

    return proposalId;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVoteBySignature(
    uint256 proposalId,
    address voter,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32[] memory underlyingAssetsWithSlotHashes = new bytes32[](
      votingBalanceProofs.length
    );
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      underlyingAssetsWithSlotHashes[i] = keccak256(
        abi.encode(
          VOTING_ASSET_WITH_SLOT_TYPEHASH,
          votingBalanceProofs[i].underlyingAsset,
          votingBalanceProofs[i].slot
        )
      );
    }

    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          VOTE_SUBMITTED_TYPEHASH,
          proposalId,
          voter,
          support,
          keccak256(abi.encodePacked(underlyingAssetsWithSlotHashes))
        )
      )
    );
    address signer = ECDSA.recover(digest, v, r, s);

    require(signer == voter && signer != address(0), Errors.INVALID_SIGNATURE);
    _submitVote(signer, proposalId, support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    _submitVote(msg.sender, proposalId, support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVoteAsRepresentativeBySignature(
    uint256 proposalId,
    address voter,
    address representative,
    bool support,
    bytes memory proofOfRepresentation,
    VotingBalanceProof[] calldata votingBalanceProofs,
    SignatureParams memory signatureParams
  ) external {
    bytes32[] memory underlyingAssetsWithSlotHashes = new bytes32[](
      votingBalanceProofs.length
    );
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      underlyingAssetsWithSlotHashes[i] = keccak256(
        abi.encode(
          VOTING_ASSET_WITH_SLOT_TYPEHASH,
          votingBalanceProofs[i].underlyingAsset,
          votingBalanceProofs[i].slot
        )
      );
    }

    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          VOTE_SUBMITTED_BY_REPRESENTATIVE_TYPEHASH,
          proposalId,
          voter,
          representative,
          support,
          keccak256(abi.encodePacked(underlyingAssetsWithSlotHashes))
        )
      )
    );
    address signer = ECDSA.recover(
      digest,
      signatureParams.v,
      signatureParams.r,
      signatureParams.s
    );

    require(
      signer == representative && signer != address(0),
      Errors.INVALID_SIGNATURE
    );

    _submitVoteAsRepresentative(
      proposalId,
      support,
      voter,
      representative,
      proofOfRepresentation,
      votingBalanceProofs
    );
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVoteAsRepresentative(
    uint256 proposalId,
    bool support,
    address voter,
    bytes memory proofOfRepresentation,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    _submitVoteAsRepresentative(
      proposalId,
      support,
      voter,
      msg.sender,
      proofOfRepresentation,
      votingBalanceProofs
    );
  }

  /**
   * @notice Function to register the vote of user as its representative
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param voter the voter address
   * @param representative address of the voter representative
   * @param proofOfRepresentation proof that can validate that msg.sender is the voter representative
   * @param votingBalanceProofs list of voting assets proofs
   */
  function _submitVoteAsRepresentative(
    uint256 proposalId,
    bool support,
    address voter,
    address representative,
    bytes memory proofOfRepresentation,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) internal {
    require(voter != address(0), Errors.INVALID_VOTER);
    bytes32 l1ProposalBlockHash = _proposalsVoteConfiguration[proposalId]
      .l1ProposalBlockHash;

    bytes32 slot = SlotUtils.getRepresentativeSlotHash(
      voter,
      block.chainid,
      REPRESENTATIVES_SLOT
    );
    StateProofVerifier.SlotValue memory storageData = DATA_WAREHOUSE.getStorage(
      GOVERNANCE,
      l1ProposalBlockHash,
      slot,
      proofOfRepresentation
    );

    address storedRepresentative = address(uint160(storageData.value));

    require(
      representative == storedRepresentative && representative != address(0),
      Errors.CALLER_IS_NOT_VOTER_REPRESENTATIVE
    );

    _submitVote(voter, proposalId, support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getUserProposalVote(
    address user,
    uint256 proposalId
  ) external view returns (Vote memory) {
    return _proposals[proposalId].votes[user];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function closeAndSendVote(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Finished,
      Errors.PROPOSAL_VOTE_NOT_FINISHED
    );

    proposal.votingClosedAndSentBlockNumber = block.number;
    proposal.votingClosedAndSentTimestamp = _getCurrentTimeRef();

    uint256 forVotes = proposal.forVotes;
    uint256 againstVotes = proposal.againstVotes;

    proposal.sentToGovernance = true;

    _sendVoteResults(proposalId, forVotes, againstVotes);

    emit ProposalResultsSent(proposalId, forVotes, againstVotes);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalById(
    uint256 proposalId
  ) external view returns (ProposalWithoutVotes memory) {
    Proposal storage proposal = _proposals[proposalId];
    ProposalWithoutVotes memory proposalWithoutVotes = ProposalWithoutVotes({
      id: proposalId,
      startTime: proposal.startTime,
      endTime: proposal.endTime,
      creationBlockNumber: proposal.creationBlockNumber,
      forVotes: proposal.forVotes,
      againstVotes: proposal.againstVotes,
      votingClosedAndSentBlockNumber: proposal.votingClosedAndSentBlockNumber,
      votingClosedAndSentTimestamp: proposal.votingClosedAndSentTimestamp,
      sentToGovernance: proposal.sentToGovernance
    });

    return proposalWithoutVotes;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalState(
    uint256 proposalId
  ) external view returns (ProposalState) {
    return _getProposalState(_proposals[proposalId]);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalsVoteConfigurationIds(
    uint256 skip,
    uint256 size
  ) external view returns (uint256[] memory) {
    uint256 proposalListLength = _proposalsVoteConfigurationIds.length;
    if (proposalListLength == 0 || proposalListLength <= skip) {
      return new uint256[](0);
    } else if (proposalListLength < size + skip) {
      size = proposalListLength - skip;
    }

    uint256[] memory ids = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      ids[i] = _proposalsVoteConfigurationIds[
        proposalListLength - skip - i - 1
      ];
    }
    return ids;
  }

  function _checkRepresentationRoots(
    bytes32 l1ProposalBlockHash
  ) internal view {
    require(
      DATA_WAREHOUSE.getStorageRoots(GOVERNANCE, l1ProposalBlockHash) !=
        bytes32(0),
      Errors.MISSING_REPRESENTATION_ROOTS
    );
  }

  /**
    * @notice method to cast a vote on a proposal specified by its id
    * @param voter address with the voting power
    * @param proposalId id of the proposal on which the vote will be cast
    * @param support boolean indicating if the vote is in favor or against the proposal
    * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
             allowed on the voting strategy.
    * @dev A vote does not need to use all the tokens allowed, can be a subset
    */
  function _submitVote(
    address voter,
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) internal {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Active,
      Errors.PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE
    );

    Vote storage vote = proposal.votes[voter];
    require(vote.votingPower == 0, Errors.PROPOSAL_VOTE_ALREADY_EXISTS);

    ProposalVoteConfiguration memory voteConfig = _proposalsVoteConfiguration[
      proposalId
    ];

    uint256 votingPower;
    StateProofVerifier.SlotValue memory balanceVotingPower;
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      for (uint256 j = i + 1; j < votingBalanceProofs.length; j++) {
        require(
          votingBalanceProofs[i].slot != votingBalanceProofs[j].slot ||
            votingBalanceProofs[i].underlyingAsset !=
            votingBalanceProofs[j].underlyingAsset,
          Errors.VOTE_ONCE_FOR_ASSET
        );
      }

      balanceVotingPower = DATA_WAREHOUSE.getStorage(
        votingBalanceProofs[i].underlyingAsset,
        voteConfig.l1ProposalBlockHash,
        SlotUtils.getAccountSlotHash(voter, votingBalanceProofs[i].slot),
        votingBalanceProofs[i].proof
      );

      require(balanceVotingPower.exists, Errors.USER_BALANCE_DOES_NOT_EXISTS);

      if (balanceVotingPower.value != 0) {
        votingPower += IVotingStrategy(address(VOTING_STRATEGY)).getVotingPower(
          votingBalanceProofs[i].underlyingAsset,
          votingBalanceProofs[i].slot,
          balanceVotingPower.value,
          voteConfig.l1ProposalBlockHash
        );
      }
    }
    require(votingPower != 0, Errors.USER_VOTING_BALANCE_IS_ZERO);

    if (support) {
      proposal.forVotes += votingPower.toUint128();
    } else {
      proposal.againstVotes += votingPower.toUint128();
    }

    vote.support = support;
    vote.votingPower = votingPower.toUint248();

    emit VoteEmitted(proposalId, voter, support, votingPower);
  }

  /**
   * @notice method to send the voting results on a proposal back to L1
   * @param proposalId id of the proposal to send the voting result to L1
   * @dev This method should be implemented to trigger the bridging flow
   */
  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal virtual;

  /**
   * @notice method to get the state of a proposal specified by its id
   * @param proposal the proposal to retrieve the state of
   * @return the state of the proposal
   */
  function _getProposalState(
    Proposal storage proposal
  ) internal view returns (ProposalState) {
    if (proposal.endTime == 0) {
      return ProposalState.NotCreated;
    } else if (_getCurrentTimeRef() <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.sentToGovernance) {
      return ProposalState.SentToGovernance;
    } else {
      return ProposalState.Finished;
    }
  }

  /**
   * @notice method to get the timestamp of a block casted to uint40
   * @return uint40 block timestamp
   */
  function _getCurrentTimeRef() internal view returns (uint40) {
    return uint40(block.timestamp);
  }

  /**
   * @notice method that registers a proposal configuration and creates the voting if it can. If not it will register the
             the configuration for later creation.
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   */
  function _createBridgedProposalVote(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) internal {
    require(
      blockHash != bytes32(0),
      Errors.INVALID_VOTE_CONFIGURATION_BLOCKHASH
    );
    require(
      votingDuration > 0,
      Errors.INVALID_VOTE_CONFIGURATION_VOTING_DURATION
    );
    require(
      _proposalsVoteConfiguration[proposalId].l1ProposalBlockHash == bytes32(0),
      Errors.PROPOSAL_VOTE_CONFIGURATION_ALREADY_BRIDGED
    );

    _proposalsVoteConfiguration[proposalId] = IVotingMachineWithProofs
      .ProposalVoteConfiguration({
        votingDuration: votingDuration,
        l1ProposalBlockHash: blockHash
      });
    _proposalsVoteConfigurationIds.push(proposalId);

    bool created;
    try this.startProposalVote(proposalId) {
      created = true;
    } catch (bytes memory) {}

    emit ProposalVoteConfigurationBridged(
      proposalId,
      blockHash,
      votingDuration,
      created
    );
  }
}
