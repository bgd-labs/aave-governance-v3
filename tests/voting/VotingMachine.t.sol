// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IVotingMachine} from '../../src/contracts/voting/interfaces/IVotingMachine.sol';
import {IVotingStrategy} from '../../src/contracts/voting/interfaces/IVotingStrategy.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {VotingMachine, IVotingMachineWithProofs} from '../../src/contracts/voting/VotingMachine.sol';
import {VotingStrategy, IBaseVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {IVotingPortal} from '../../src/interfaces/IVotingPortal.sol';
import {ChainIds} from 'aave-delivery-infrastructure/contracts/libs/ChainIds.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {BridgingHelper} from '../../src/contracts/libraries/BridgingHelper.sol';

// Mocked so we can make it revert
contract MockVotingStrategy {
  IDataWarehouse public immutable DATA_WAREHOUSE =
    IDataWarehouse(address(123401234));

  function hasRequiredRoots(bytes32) external pure {
    revert('');
  }
}

contract VotingMachineMock is VotingMachine {
  constructor(
    address crossChainController,
    uint256 gasLimit,
    uint256 l1VotingPortalChainId,
    IVotingStrategy votingStrategy,
    address l1VotingPortal,
    address governance
  )
    VotingMachine(
      crossChainController,
      gasLimit,
      l1VotingPortalChainId,
      votingStrategy,
      l1VotingPortal,
      governance
    )
  {}

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
}

contract VotingMachineTest is Test {
  address public constant CROSS_CHAIN_CONTROLLER = address(123);
  address public constant L1_VOTING_PORTAL = address(1234);
  address public constant GOVERNANCE = address(12345);
  uint256 L1_VOTING_PORTAL_CHAIN_ID;
  uint256 public constant GAS_LIMIT = 600000;

  address public VOTING_STRATEGY = address(new MockVotingStrategy());

  IVotingMachine votingMachine;

  event GasLimitUpdated(uint256 indexed gasLimit);
  event L1VotingPortalUpdated(address indexed l1VotingPortal);
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
    IVotingMachineWithProofs.VotingAssetWithSlot[] votingTokens
  );

  event MessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    BridgingHelper.MessageType messageType,
    bytes message,
    bytes reason
  );
  event IncorrectTypeMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bytes message,
    bytes reason
  );

  function setUp() public {
    L1_VOTING_PORTAL_CHAIN_ID = ChainIds.ETHEREUM;
    votingMachine = new VotingMachineMock(
      CROSS_CHAIN_CONTROLLER,
      GAS_LIMIT,
      L1_VOTING_PORTAL_CHAIN_ID,
      IVotingStrategy(VOTING_STRATEGY),
      L1_VOTING_PORTAL,
      GOVERNANCE
    );
  }

  function testContractCreationWhenInvalidGov() public {
    vm.expectRevert(bytes(Errors.VM_INVALID_GOVERNANCE_ADDRESS));
    new VotingMachine(
      CROSS_CHAIN_CONTROLLER,
      GAS_LIMIT,
      L1_VOTING_PORTAL_CHAIN_ID,
      IVotingStrategy(VOTING_STRATEGY),
      L1_VOTING_PORTAL,
      address(0)
    );
  }

  function testContractCreationWhenInvalidCCC() public {
    vm.expectRevert(
      bytes(Errors.INVALID_VOTING_MACHINE_CROSS_CHAIN_CONTROLLER)
    );
    new VotingMachine(
      address(0),
      GAS_LIMIT,
      L1_VOTING_PORTAL_CHAIN_ID,
      IVotingStrategy(VOTING_STRATEGY),
      L1_VOTING_PORTAL,
      GOVERNANCE
    );
  }

  function testContractCreationWhenInvalidVotingPortal() public {
    vm.expectRevert(
      bytes(Errors.INVALID_VOTING_PORTAL_ADDRESS_IN_VOTING_MACHINE)
    );
    new VotingMachine(
      CROSS_CHAIN_CONTROLLER,
      GAS_LIMIT,
      L1_VOTING_PORTAL_CHAIN_ID,
      IVotingStrategy(VOTING_STRATEGY),
      address(0),
      GOVERNANCE
    );
  }

  function testContractCreationWhenInvalidChainId() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_PORTAL_CHAIN_ID));
    new VotingMachine(
      CROSS_CHAIN_CONTROLLER,
      GAS_LIMIT,
      0,
      IVotingStrategy(VOTING_STRATEGY),
      L1_VOTING_PORTAL,
      GOVERNANCE
    );
  }

  function testUpdateGasLimit() public {
    uint256 newGasLimit = 500_000;
    vm.expectEmit(true, false, false, true);
    emit GasLimitUpdated(newGasLimit);
    votingMachine.updateGasLimit(newGasLimit);

    assertEq(votingMachine.getGasLimit(), newGasLimit);
  }

  function testUpdateGasLimitWhenNotOwner() public {
    uint256 newGasLimit = 500_000;
    hoax(address(2332));
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    votingMachine.updateGasLimit(newGasLimit);
  }

  function testInitialization() public {
    assertEq(votingMachine.CROSS_CHAIN_CONTROLLER(), CROSS_CHAIN_CONTROLLER);
    assertEq(
      uint8(votingMachine.L1_VOTING_PORTAL_CHAIN_ID()),
      uint8(L1_VOTING_PORTAL_CHAIN_ID)
    );
  }

  // TEST LOGIC
  function testReceiveCrossChainMessage() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );
    bytes memory empty;

    vm.mockCall(
      address(VOTING_STRATEGY),
      abi.encodeWithSelector(
        IVotingStrategy.hasRequiredRoots.selector,
        blockHash
      ),
      abi.encode()
    );

    vm.mockCall(
      address(MockVotingStrategy(VOTING_STRATEGY).DATA_WAREHOUSE()),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector),
      abi.encode(keccak256(abi.encode('test')))
    );

    vm.expectEmit(true, true, true, true);
    emit ProposalVoteConfigurationBridged(
      proposalId,
      blockHash,
      votingDuration,
      true
    );
    vm.expectEmit(true, true, true, true);
    emit MessageReceived(
      originSender,
      originChainId,
      true,
      BridgingHelper.MessageType.Proposal_Vote,
      message,
      empty
    );
    hoax(CROSS_CHAIN_CONTROLLER);
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );

    IVotingMachineWithProofs.ProposalVoteConfiguration
      memory config = IVotingMachineWithProofs(address(votingMachine))
        .getProposalVoteConfiguration(proposalId);
    assertEq(config.votingDuration, votingDuration);
    assertEq(config.l1ProposalBlockHash, blockHash);
  }

  function testReceiveCrossChainMessageWithWrongProposalMessage() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes memory message = abi.encode(proposalId);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );

    hoax(CROSS_CHAIN_CONTROLLER);
    bytes memory reason;
    vm.expectEmit(true, true, true, true);
    emit MessageReceived(
      originSender,
      originChainId,
      false,
      BridgingHelper.MessageType.Proposal_Vote,
      message,
      reason
    );
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithWrongMessageType() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes memory message = abi.encode(proposalId);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Null,
      message
    );

    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectEmit(true, true, true, true);
    emit IncorrectTypeMessageReceived(
      originSender,
      originChainId,
      message,
      abi.encodePacked(
        'unsupported message type: ',
        BridgingHelper.MessageType.Null
      )
    );
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithWrongSender() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );

    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithWrongOriginSender() public {
    address originSender = address(0);
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );

    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithWrongOriginChainId() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = ChainIds.POLYGON;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );
    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithWrongType() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(uint8(4), message);
    hoax(CROSS_CHAIN_CONTROLLER);
    bytes memory reason;
    vm.expectEmit(true, true, false, true);
    emit IncorrectTypeMessageReceived(
      originSender,
      originChainId,
      messageWithType,
      reason
    );
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWithoutRoots() public {
    address originSender = L1_VOTING_PORTAL;
    uint256 originChainId = L1_VOTING_PORTAL_CHAIN_ID;

    // message info
    uint256 proposalId = 0;
    bytes32 blockHash = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
    uint24 votingDuration = uint24(1234);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      BridgingHelper.MessageType.Proposal_Vote,
      message
    );

    hoax(CROSS_CHAIN_CONTROLLER);

    vm.expectEmit(true, true, true, true);
    emit ProposalVoteConfigurationBridged(
      proposalId,
      blockHash,
      votingDuration,
      false
    );
    votingMachine.receiveCrossChainMessage(
      originSender,
      originChainId,
      messageWithType
    );

    IVotingMachineWithProofs.ProposalVoteConfiguration
      memory config = IVotingMachineWithProofs(address(votingMachine))
        .getProposalVoteConfiguration(proposalId);
    assertEq(config.votingDuration, votingDuration);
    assertEq(config.l1ProposalBlockHash, blockHash);
  }
}
