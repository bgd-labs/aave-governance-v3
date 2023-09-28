// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdStorage.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
import {IVotingMachineWithProofs} from '../../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {IVotingStrategy} from '../../src/contracts/voting/interfaces/IVotingStrategy.sol';
import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {VotingStrategy, IBaseVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {VotingMachineWithProofs, StateProofVerifier} from '../../src/contracts/voting/VotingMachineWithProofs.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';

contract VotingMachine is VotingMachineWithProofs {
  constructor(
    IVotingStrategy votingStrategy,
    address governance
  ) VotingMachineWithProofs(votingStrategy, governance) {}

  function setProposalsVoteConfiguration(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    _proposalsVoteConfiguration[proposalId] = IVotingMachineWithProofs
      .ProposalVoteConfiguration({
        votingDuration: votingDuration,
        l1ProposalBlockHash: blockHash
      });
  }

  function setProposalVote(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    _createBridgedProposalVote(proposalId, blockHash, votingDuration);
  }

  function setProposalVote(
    uint256 proposalId,
    address voter,
    bool support,
    uint248 votingPower
  ) external {
    _proposals[proposalId].votes[voter].votingPower = votingPower;
    _proposals[proposalId].votes[voter].support = support;
  }

  function setProposal(uint256 proposalId) external {
    Proposal storage newProposal = _proposals[proposalId];
    newProposal.id = proposalId;
  }

  function setProposalsVoteConfigurationIds(uint256[] memory ids) external {
    _proposalsVoteConfigurationIds = ids;
  }

  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal override {}
}

contract VotingMachineWithProofsTest is Test {
  bytes32 BLOCK_HASH =
    0xf656a10e5d825e287890cc430cf1bac2364b756e09e19b6fa3a72ec844ba2f44;
  address VOTER = 0x6D603081563784dB3f83ef1F65Cc389D94365Ac9;
  address public constant GOVERNANCE = address(12345);

  IDataWarehouse dataWarehouse;
  IVotingStrategy votingStrategy;
  IVotingMachineWithProofs votingMachine;

  event ProposalVoteConfigurationBridged(
    uint256 indexed proposalId,
    bytes32 indexed blockHash,
    uint24 votingDuration,
    bool indexed voteCreated
  );
  event VoteBridged(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    IVotingMachineWithProofs.VotingAssetWithSlot[] votingAssetsWithSlot
  );
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    uint256 votingPower
  );
  event ProposalResultsSent(
    uint256 indexed proposalId,
    uint256 forVotes,
    uint256 againstVotes
  );
  event ProposalVoteClosed(uint256 indexed proposalId, uint256 endedBlock);
  event ProposalVoteStarted(
    uint256 indexed proposalId,
    bytes32 indexed l1BlockHash,
    uint256 startTime,
    uint256 endTime
  );

  function setUp() public {
    // this is needed instead of mocks to test gas
    // deploy dependencies
    dataWarehouse = new DataWarehouse();

    votingStrategy = new VotingStrategy(address(dataWarehouse));

    votingMachine = new VotingMachine(votingStrategy, GOVERNANCE);
  }

  function testContractCreation() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_STRATEGY));
    new VotingMachine(IVotingStrategy(address(0)), GOVERNANCE);
  }

  function testContractCreationInvalidGov() public {
    vm.expectRevert(bytes(Errors.VM_INVALID_GOVERNANCE_ADDRESS));
    new VotingMachine(votingStrategy, address(0));
  }

  // TEST GETTERS
  function testGetProposalVoteConfiguration() public {
    uint256 proposalId = 3;
    uint24 votingDuration = 123;
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );
    IVotingMachineWithProofs.ProposalVoteConfiguration
      memory config = votingMachine.getProposalVoteConfiguration(proposalId);
    assertEq(config.l1ProposalBlockHash, BLOCK_HASH);
    assertEq(config.votingDuration, votingDuration);
  }

  function testGetProposalVoteConfigurationWhenNotExists() public {
    IVotingMachineWithProofs.ProposalVoteConfiguration
      memory config = votingMachine.getProposalVoteConfiguration(0);
    assertEq(config.l1ProposalBlockHash, bytes32(0));
    assertEq(config.votingDuration, uint24(0));
  }

  function testGetDataWarehouse() public {
    assertEq(address(votingMachine.DATA_WAREHOUSE()), address(dataWarehouse));
  }

  function testGetVotingStrategy() public {
    assertEq(address(votingMachine.VOTING_STRATEGY()), address(votingStrategy));
  }

  function testGetUserProposalVote() public {
    uint256 proposalId = 3;
    address voter = address(1230123);
    bool support = true;
    uint248 votingPower = uint248(1234);
    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      voter,
      support,
      votingPower
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(voter, proposalId);

    assertEq(vote.support, true);
    assertEq(vote.votingPower, votingPower);
  }

  function testGetUserProposalVoteWhenNoVote() public {
    address user = address(1230123);
    uint256 proposalId = 4;
    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(user, proposalId);

    assertEq(vote.support, false);
    assertEq(vote.votingPower, uint248(0));
  }

  function testGetProposalById() public {
    uint256 proposalId = 3;
    VotingMachine(address(votingMachine)).setProposal(proposalId);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
  }

  function testGetProposalByIdWhenNotExists() public {
    uint256 proposalId = 3;

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
  }

  function testGetProposalState() public {
    uint256 proposalId = 3;

    IVotingMachineWithProofs.ProposalState proposalState = votingMachine
      .getProposalState(proposalId);

    assertEq(
      uint8(proposalState),
      uint8(IVotingMachineWithProofs.ProposalState.NotCreated)
    );
  }

  function testGetProposalsVoteConfigurationIdsWhenLength0() public {
    uint256 skip = 2;
    uint256 size = 5;

    uint256[] memory resultIds = votingMachine.getProposalsVoteConfigurationIds(
      skip,
      size
    );

    assertEq(resultIds.length, 0);
  }

  function testGetProposalsVoteConfigurationIdsWhenSkipAndSizeCorrect() public {
    uint256 skip = 2;
    uint256 size = 5;

    uint256[] memory ids = new uint256[](10);
    ids[0] = 0;
    ids[1] = 1;
    ids[2] = 2;
    ids[3] = 3;
    ids[4] = 4;
    ids[5] = 5;
    ids[6] = 6;
    ids[7] = 7;
    ids[8] = 8;
    ids[9] = 9;

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(ids);

    uint256[] memory resultIds = votingMachine.getProposalsVoteConfigurationIds(
      skip,
      size
    );

    assertEq(resultIds.length, 5);
    assertEq(resultIds[0], 7);
    assertEq(resultIds[1], 6);
    assertEq(resultIds[2], 5);
    assertEq(resultIds[3], 4);
    assertEq(resultIds[4], 3);
  }

  function testGetProposalsVoteConfigurationIdsWhenSkipAndSizeToBig() public {
    uint256 skip = 2;
    uint256 size = 12;

    uint256[] memory ids = new uint256[](10);
    ids[0] = 0;
    ids[1] = 1;
    ids[2] = 2;
    ids[3] = 3;
    ids[4] = 4;
    ids[5] = 5;
    ids[6] = 6;
    ids[7] = 7;
    ids[8] = 8;
    ids[9] = 9;

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(ids);

    uint256[] memory resultIds = votingMachine.getProposalsVoteConfigurationIds(
      skip,
      size
    );

    assertEq(resultIds.length, 8);
    assertEq(resultIds[0], 7);
    assertEq(resultIds[1], 6);
    assertEq(resultIds[2], 5);
    assertEq(resultIds[3], 4);
    assertEq(resultIds[4], 3);
    assertEq(resultIds[5], 2);
    assertEq(resultIds[6], 1);
    assertEq(resultIds[7], 0);
  }

  function testGetProposalsVoteConfigurationIdsWhenSkipToBig() public {
    uint256 skip = 12;
    uint256 size = 5;

    uint256[] memory ids = new uint256[](10);
    ids[0] = 0;
    ids[1] = 1;
    ids[2] = 2;
    ids[3] = 3;
    ids[4] = 4;
    ids[5] = 5;
    ids[6] = 6;
    ids[7] = 7;
    ids[8] = 8;
    ids[9] = 9;

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(ids);

    uint256[] memory resultIds = votingMachine.getProposalsVoteConfigurationIds(
      skip,
      size
    );

    assertEq(resultIds.length, 0);
  }

  function testGetProposalsVoteConfigurationIdsWhenSkipAndSizeBiggerThanLength()
    public
  {
    uint256 skip = 6;
    uint256 size = 5;

    uint256[] memory ids = new uint256[](10);
    ids[0] = 0;
    ids[1] = 1;
    ids[2] = 2;
    ids[3] = 3;
    ids[4] = 4;
    ids[5] = 5;
    ids[6] = 6;
    ids[7] = 7;
    ids[8] = 8;
    ids[9] = 9;

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(ids);

    uint256[] memory resultIds = votingMachine.getProposalsVoteConfigurationIds(
      skip,
      size
    );

    assertEq(resultIds.length, 4);
    assertEq(resultIds[0], 3);
    assertEq(resultIds[1], 2);
    assertEq(resultIds[2], 1);
    assertEq(resultIds[3], 0);
  }

  // TEST CREATE VOTE
  function testCreateVote() public {
    uint256 proposalId = 2;
    uint24 votingDuration = uint24(62341);

    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );

    uint48 startTime = uint48(block.timestamp);
    uint48 endTime = startTime + votingDuration;

    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        IVotingStrategy.hasRequiredRoots.selector,
        BLOCK_HASH
      ),
      abi.encode()
    );

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector),
      abi.encode(keccak256(abi.encode('test')))
    );
    vm.expectEmit(true, true, true, true);
    emit ProposalVoteStarted(proposalId, BLOCK_HASH, startTime, endTime);
    uint256 createdProposalId = votingMachine.startProposalVote(proposalId);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(createdProposalId);

    assertEq(proposal.id, proposalId);
    assertEq(createdProposalId, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.startTime, startTime);
    assertEq(proposal.endTime, endTime);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(0));
    assertEq(proposal.againstVotes, uint128(0));
    assertEq(proposal.creationBlockNumber, block.number);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );
  }

  function testCreateVoteWhenWrongProposalState() public {
    uint256 proposalId = 2;
    uint24 votingDuration = uint24(62341);

    _createVote(proposalId, votingDuration);

    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_ALREADY_CREATED));
    votingMachine.startProposalVote(proposalId);
  }

  function testCreateVoteWhenBlockhashNotRegistered() public {
    uint256 proposalId = 2;

    vm.expectRevert(bytes(Errors.MISSING_PROPOSAL_BLOCK_HASH));
    votingMachine.startProposalVote(proposalId);
  }

  function testCreateVoteWhenNotRegisteredRoots() public {
    uint256 proposalId = 2;
    uint24 votingDuration = uint24(62341);

    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );

    vm.expectRevert(bytes(Errors.MISSING_AAVE_ROOTS));
    votingMachine.startProposalVote(proposalId);
  }

  // TEST SUBMIT VOTE
  function testSubmitVoteInFavor() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    // Expects call to voting strategy saved on proposal creation
    vm.expectCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      )
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(proposalId, address(this), true, votingPower);
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(votingPower));
    assertEq(proposal.againstVotes, uint128(0));

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteInFavorWithSameAssetDiffSlots() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        2
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });
    votingBalanceProofs[1] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 1,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[1].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[1].slot
        ),
        votingBalanceProofs[1].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[1].underlyingAsset,
        votingBalanceProofs[1].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(proposalId, address(this), true, votingPower * 2);
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(votingPower * 2));
    assertEq(proposal.againstVotes, uint128(0));

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower * 2);
  }

  function testSubmitVoteAgainst() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = false;
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(proposalId, address(this), false, votingPower);
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(0));
    assertEq(proposal.againstVotes, uint128(votingPower));

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteWithRepeatedAssets() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        2
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });
    votingBalanceProofs[1] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectRevert(bytes(Errors.VOTE_ONCE_FOR_ASSET));
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);
  }

  function testSubmitVoteWhenNotCorrectState() public {
    uint256 proposalId = 8;

    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE));
    votingMachine.submitVote(
      proposalId,
      true,
      new IVotingMachineWithProofs.VotingBalanceProof[](0)
    );
  }

  function testSubmitWhenAlreadyVoted() public {
    uint256 proposalId = 1;
    uint24 votingDuration = 600;
    uint256 votingPower = 12e18;
    uint256 balance = 23e18;
    bool support = true;

    _createVote(proposalId, votingDuration);

    _submitVote(proposalId, support);

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorage.selector),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_ALREADY_EXISTS));
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitWhenVotedWithDifferentSupport() public {
    uint256 proposalId = 1;
    uint24 votingDuration = 600;
    uint256 votingPower = 12e18;
    uint256 balance = 23e18;
    bool support = true;

    _createVote(proposalId, votingDuration);

    _submitVote(proposalId, support);

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorage.selector),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_ALREADY_EXISTS));
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteWhenUserBalanceDoesNotExist() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: false, value: 0}))
    );

    vm.expectRevert(bytes(Errors.USER_BALANCE_DOES_NOT_EXISTS));
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);
  }

  function testSubmitVoteWhenUserVotingPowerIs0() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    uint256 balance = 23e18;

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(0)
    );

    vm.expectRevert(bytes(Errors.USER_VOTING_BALANCE_IS_ZERO));
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);
  }

  // TEST SUBMIT VOTE AS REPRESENTATIVE
  function testSubmitVoteAsRepresentative() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;
    address voter = address(this);
    address representative = address(84123795);
    bytes memory proofOfRepresentation = abi.encode('test');

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    bytes32 slot = SlotUtils.getRepresentativeSlotHash(
      voter,
      block.chainid,
      votingMachine.REPRESENTATIVES_SLOT()
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingMachine.GOVERNANCE(),
        BLOCK_HASH,
        slot,
        proofOfRepresentation
      ),
      abi.encode(
        StateProofVerifier.SlotValue({
          value: 0x000000000000000000000000000000000000000000000000000000000503a093,
          exists: true
        })
      )
    );

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingBalanceProofs[0].underlyingAsset,
        BLOCK_HASH,
        SlotUtils.getAccountSlotHash(
          address(this),
          votingBalanceProofs[0].slot
        ),
        votingBalanceProofs[0].proof
      ),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    // Expects call to voting strategy saved on proposal creation
    vm.expectCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      )
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    hoax(representative);
    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(proposalId, address(this), true, votingPower);
    votingMachine.submitVoteAsRepresentative(
      proposalId,
      support,
      voter,
      proofOfRepresentation,
      votingBalanceProofs
    );

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(votingPower));
    assertEq(proposal.againstVotes, uint128(0));

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteAsRepresentativeWhenInvalidRepresentative() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    address voter = address(this);
    bytes memory proofOfRepresentation = abi.encode('test');

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    bytes32 slot = SlotUtils.getRepresentativeSlotHash(
      voter,
      block.chainid,
      votingMachine.REPRESENTATIVES_SLOT()
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingMachine.GOVERNANCE(),
        BLOCK_HASH,
        slot,
        proofOfRepresentation
      ),
      abi.encode(
        StateProofVerifier.SlotValue({
          value: 0x000000000000000000000000000000000000000000000000000000000503a093,
          exists: true
        })
      )
    );

    hoax(address(235));
    vm.expectRevert(bytes(Errors.CALLER_IS_NOT_VOTER_REPRESENTATIVE));
    votingMachine.submitVoteAsRepresentative(
      proposalId,
      support,
      voter,
      proofOfRepresentation,
      votingBalanceProofs
    );
  }

  function testSubmitVoteAsRepresentativeWhenRepresentative0() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    address voter = address(this);
    bytes memory proofOfRepresentation = abi.encode('test');

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    bytes32 slot = SlotUtils.getRepresentativeSlotHash(
      voter,
      block.chainid,
      votingMachine.REPRESENTATIVES_SLOT()
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingMachine.GOVERNANCE(),
        BLOCK_HASH,
        slot,
        proofOfRepresentation
      ),
      abi.encode(
        StateProofVerifier.SlotValue({
          value: 0x0000000000000000000000000000000000000000000000000000000000000000,
          exists: true
        })
      )
    );

    hoax(address(0));
    vm.expectRevert(bytes(Errors.CALLER_IS_NOT_VOTER_REPRESENTATIVE));
    votingMachine.submitVoteAsRepresentative(
      proposalId,
      support,
      voter,
      proofOfRepresentation,
      votingBalanceProofs
    );
  }

  function testSubmitVoteAsRepresentativeWhenInvalidVoter() public {
    uint256 proposalId = 0;
    uint24 votingDuration = 600;
    bool support = true;
    bytes memory proofOfRepresentation = abi.encode('test');

    _createVote(proposalId, votingDuration);
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    hoax(address(235));
    vm.expectRevert(bytes(Errors.INVALID_VOTER));
    votingMachine.submitVoteAsRepresentative(
      proposalId,
      support,
      address(0),
      proofOfRepresentation,
      votingBalanceProofs
    );
  }

  // TEST SUBMIT VOTE WITH SIGNATURE

  function _getVotingAssetsWithSlotHash(
    IVotingMachineWithProofs.VotingAssetWithSlot[] memory votingAssetsWithSlot
  ) internal view returns (bytes32) {
    bytes32[] memory votingAssetsWithSlotHashes = new bytes32[](
      votingAssetsWithSlot.length
    );

    for (uint256 i = 0; i < votingAssetsWithSlotHashes.length; i++) {
      votingAssetsWithSlotHashes[i] = keccak256(
        abi.encode(
          votingMachine.VOTING_ASSET_WITH_SLOT_TYPEHASH(),
          votingAssetsWithSlot[i].underlyingAsset,
          votingAssetsWithSlot[i].slot
        )
      );
    }
    return keccak256(abi.encodePacked(votingAssetsWithSlotHashes));
  }

  function testSubmitVoteBySignature() public {
    uint256 proposalId = 2;
    bool support = true;

    _createVote(proposalId, 600);

    IVotingMachineWithProofs.VotingAssetWithSlot[]
      memory votingAssetsWithSlot = new IVotingMachineWithProofs.VotingAssetWithSlot[](
        1
      );
    votingAssetsWithSlot[0].underlyingAsset = IBaseVotingStrategy(
      address(votingStrategy)
    ).AAVE();
    votingAssetsWithSlot[0].slot = 0;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: votingAssetsWithSlot[0].underlyingAsset,
      slot: votingAssetsWithSlot[0].slot,
      proof: bytes('')
    });

    address signer = vm.addr(1);
    bytes32 digest = ECDSA.toTypedDataHash(
      votingMachine.DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          votingMachine.VOTE_SUBMITTED_TYPEHASH(),
          proposalId,
          signer,
          support,
          _getVotingAssetsWithSlotHash(votingAssetsWithSlot)
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorage.selector),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );

    hoax(signer);
    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(proposalId, signer, true, votingPower);
    votingMachine.submitVoteBySignature(
      proposalId,
      signer,
      support,
      votingBalanceProofs,
      v,
      r,
      s
    );

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);

    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(votingPower));
    assertEq(proposal.againstVotes, uint128(0));

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(signer, proposalId);
    assertEq(vote.support, support);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteBySignatureWrongAssetShouldRevert() public {
    uint256 proposalId = 2;
    bool support = true;

    _createVote(proposalId, 600);

    IVotingMachineWithProofs.VotingAssetWithSlot[]
      memory votingAssetsWithSlot = new IVotingMachineWithProofs.VotingAssetWithSlot[](
        1
      );
    votingAssetsWithSlot[0].underlyingAsset = IBaseVotingStrategy(
      address(votingStrategy)
    ).AAVE();
    votingAssetsWithSlot[0].slot = 0;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: address(11),
      slot: votingAssetsWithSlot[0].slot,
      proof: bytes('')
    });

    address signer = vm.addr(1);

    bytes32 digest = ECDSA.toTypedDataHash(
      votingMachine.DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          votingMachine.VOTE_SUBMITTED_TYPEHASH(),
          proposalId,
          signer,
          support,
          _getVotingAssetsWithSlotHash(votingAssetsWithSlot)
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    hoax(signer);
    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));
    votingMachine.submitVoteBySignature(
      proposalId,
      signer,
      support,
      votingBalanceProofs,
      v,
      r,
      s
    );
  }

  function testSubmitVoteBySignatureWrongSlotShouldRevert() public {
    uint256 proposalId = 2;
    bool support = true;

    _createVote(proposalId, 600);

    IVotingMachineWithProofs.VotingAssetWithSlot[]
      memory votingAssetsWithSlot = new IVotingMachineWithProofs.VotingAssetWithSlot[](
        1
      );
    votingAssetsWithSlot[0].underlyingAsset = IBaseVotingStrategy(
      address(votingStrategy)
    ).AAVE();
    votingAssetsWithSlot[0].slot = 0;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: votingAssetsWithSlot[0].underlyingAsset,
      slot: 111,
      proof: bytes('')
    });

    address signer = vm.addr(1);
    bytes32 digest = ECDSA.toTypedDataHash(
      votingMachine.DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          votingMachine.VOTE_SUBMITTED_TYPEHASH(),
          proposalId,
          signer,
          support,
          _getVotingAssetsWithSlotHash(votingAssetsWithSlot)
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    hoax(signer);
    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));
    votingMachine.submitVoteBySignature(
      proposalId,
      signer,
      support,
      votingBalanceProofs,
      v,
      r,
      s
    );
  }

  function testSubmitVoteBySignatureWhenSigner0() public {
    uint256 proposalId = 2;
    bool support = true;

    _createVote(proposalId, 600);

    vm.expectRevert(
      bytes("ECDSA: invalid signature")
    );
    votingMachine.submitVoteBySignature(
      proposalId,
      address(0),
      support,
      new IVotingMachineWithProofs.VotingBalanceProof[](0),
      uint8(0),
      bytes32(0),
      bytes32(0)
    );
  }

  // TEST SUBMIT VOTE WITH SIGNATURE AS REPRESENTATIVE

  function testSubmitVoteBySignatureAsRepresentative() public {
    _createVote(2, 600);

    IVotingMachineWithProofs.VotingAssetWithSlot[]
      memory votingAssetsWithSlot = new IVotingMachineWithProofs.VotingAssetWithSlot[](
        1
      );
    votingAssetsWithSlot[0].underlyingAsset = IBaseVotingStrategy(
      address(votingStrategy)
    ).AAVE();
    votingAssetsWithSlot[0].slot = 0;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: votingAssetsWithSlot[0].underlyingAsset,
      slot: votingAssetsWithSlot[0].slot,
      proof: bytes('')
    });

    address signer = vm.addr(1);
    bytes32 digest = ECDSA.toTypedDataHash(
      votingMachine.DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          votingMachine.VOTE_SUBMITTED_BY_REPRESENTATIVE_TYPEHASH(),
          2,
          address(this),
          signer,
          true,
          _getVotingAssetsWithSlotHash(votingAssetsWithSlot)
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    uint256 votingPower = 12e18;

    IVotingMachineWithProofs.SignatureParams
      memory signatureParams = IVotingMachineWithProofs.SignatureParams({
        v: v,
        r: r,
        s: s
      });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(
        IDataWarehouse.getStorage.selector,
        votingMachine.GOVERNANCE(),
        BLOCK_HASH,
        SlotUtils.getRepresentativeSlotHash(
          address(this),
          block.chainid,
          votingMachine.REPRESENTATIVES_SLOT()
        ),
        abi.encode('test')
      ),
      abi.encode(
        StateProofVerifier.SlotValue({
          value: uint256(uint160(signer)),
          exists: true
        })
      )
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorage.selector),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: 23e18}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        23e18,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );

    vm.expectEmit(true, true, true, true);
    emit VoteEmitted(2, address(this), true, votingPower);
    votingMachine.submitVoteAsRepresentativeBySignature(
      2,
      address(this),
      signer,
      true,
      abi.encode('test'),
      votingBalanceProofs,
      signatureParams
    );

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(2);

    assertEq(proposal.id, 2);
    assertEq(proposal.sentToGovernance, false);
    assertEq(proposal.votingClosedAndSentTimestamp, uint48(0));
    assertEq(proposal.forVotes, uint128(votingPower));
    assertEq(proposal.againstVotes, uint128(0));

    assertEq(
      uint8(votingMachine.getProposalState(2)),
      uint8(IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(address(this), 2);
    assertEq(vote.support, true);
    assertEq(vote.votingPower, votingPower);
  }

  function testSubmitVoteBySignatureAsRepresentativeWhenWrongVoter() public {
    _createVote(2, 600);

    IVotingMachineWithProofs.VotingAssetWithSlot[]
      memory votingAssetsWithSlot = new IVotingMachineWithProofs.VotingAssetWithSlot[](
        1
      );
    votingAssetsWithSlot[0].underlyingAsset = IBaseVotingStrategy(
      address(votingStrategy)
    ).AAVE();
    votingAssetsWithSlot[0].slot = 0;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: votingAssetsWithSlot[0].underlyingAsset,
      slot: votingAssetsWithSlot[0].slot,
      proof: bytes('')
    });

    address signer = vm.addr(1);
    bytes32 digest = ECDSA.toTypedDataHash(
      votingMachine.DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          votingMachine.VOTE_SUBMITTED_BY_REPRESENTATIVE_TYPEHASH(),
          2,
          address(1234),
          signer,
          true,
          _getVotingAssetsWithSlotHash(votingAssetsWithSlot)
        )
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    IVotingMachineWithProofs.SignatureParams
      memory signatureParams = IVotingMachineWithProofs.SignatureParams({
        v: v,
        r: r,
        s: s
      });

    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));
    votingMachine.submitVoteAsRepresentativeBySignature(
      2,
      address(this),
      signer,
      true,
      abi.encode('test'),
      votingBalanceProofs,
      signatureParams
    );
  }

  // TEST SEND VOTE RESULT
  function testCloseSendVoteResult() public {
    uint256 proposalId = 3;
    uint24 votingDuration = 600;

    _createVote(proposalId, votingDuration);

    _submitVote(proposalId, true);

    skip(votingDuration + 1);
    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposalBefore = votingMachine.getProposalById(proposalId);
    vm.expectEmit(true, false, false, true);
    emit ProposalResultsSent(
      proposalId,
      proposalBefore.forVotes,
      proposalBefore.againstVotes
    );
    votingMachine.closeAndSendVote(proposalId);

    IVotingMachineWithProofs.ProposalWithoutVotes
      memory proposal = votingMachine.getProposalById(proposalId);
    assertEq(proposal.id, proposalId);
    assertEq(proposal.sentToGovernance, true);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.SentToGovernance)
    );
  }

  function testCloseSendVoteResultWhenIncorrectState() public {
    uint256 proposalId = 3;
    uint24 votingDuration = 600;

    _createVote(proposalId, votingDuration);

    _submitVote(proposalId, true);

    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_NOT_FINISHED));
    votingMachine.closeAndSendVote(proposalId);
  }

  function testCreateBridgedProposal() public {
    uint256 proposalId = 0;
    bytes32 blockHash = bytes32('block hash');
    uint24 votingDuration = 600;

    vm.mockCall(
      address(votingMachine),
      abi.encodeWithSelector(
        IVotingMachineWithProofs.startProposalVote.selector,
        proposalId
      ),
      abi.encode(1)
    );
    vm.expectEmit(true, true, true, true);
    emit ProposalVoteConfigurationBridged(
      proposalId,
      blockHash,
      votingDuration,
      true
    );
    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      blockHash,
      votingDuration
    );

    IVotingMachineWithProofs.ProposalVoteConfiguration
      memory proposalConfig = IVotingMachineWithProofs(address(votingMachine))
        .getProposalVoteConfiguration(proposalId);
    assertEq(proposalConfig.votingDuration, votingDuration);
    assertEq(proposalConfig.l1ProposalBlockHash, blockHash);
  }

  function testCreateBridgedProposalWhenInvalidHash() public {
    uint256 proposalId = 0;
    bytes32 blockHash = bytes32(0);
    uint24 votingDuration = 600;

    vm.expectRevert(bytes(Errors.INVALID_VOTE_CONFIGURATION_BLOCKHASH));
    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      blockHash,
      votingDuration
    );
  }

  function testCreateBridgedProposalWhenInvalidDuration() public {
    uint256 proposalId = 0;
    bytes32 blockHash = bytes32('block hash');
    uint24 votingDuration = 0;

    vm.expectRevert(bytes(Errors.INVALID_VOTE_CONFIGURATION_VOTING_DURATION));
    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      blockHash,
      votingDuration
    );
  }

  function testCreateBridgedProposalWhenAlreadyRegistered() public {
    uint256 proposalId = 0;
    bytes32 blockHash = bytes32('block hash');
    uint24 votingDuration = 600;

    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      blockHash,
      votingDuration
    );

    vm.expectRevert(bytes(Errors.PROPOSAL_VOTE_CONFIGURATION_ALREADY_BRIDGED));
    VotingMachine(address(votingMachine)).setProposalVote(
      proposalId,
      blockHash,
      votingDuration
    );
  }

  // HELPER METHODS
  function _createVote(uint256 proposalId, uint24 votingDuration) public {
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );

    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        IVotingStrategy.hasRequiredRoots.selector,
        BLOCK_HASH
      ),
      abi.encode()
    );
    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector),
      abi.encode(keccak256(abi.encode('test')))
    );
    votingMachine.startProposalVote(proposalId);
  }

  function _submitVote(uint256 proposalId, bool support) internal {
    uint256 balance = 23e18;
    uint256 votingPower = 12e18;

    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      slot: 0,
      proof: bytes('')
    });

    vm.mockCall(
      address(dataWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorage.selector),
      abi.encode(StateProofVerifier.SlotValue({exists: true, value: balance}))
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(
        VotingStrategy.getVotingPower.selector,
        votingBalanceProofs[0].underlyingAsset,
        votingBalanceProofs[0].slot,
        balance,
        BLOCK_HASH
      ),
      abi.encode(votingPower)
    );
    votingMachine.submitVote(proposalId, support, votingBalanceProofs);

    vm.clearMockedCalls();
  }

  function _getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}
