// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IVotingPortal} from '../src/interfaces/IVotingPortal.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {VotingPortal, IGovernanceCore, IVotingMachineWithProofs} from '../src/contracts/VotingPortal.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {ICrossChainReceiver} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainReceiver.sol';
import {Errors} from '../src/contracts/libraries/Errors.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';

contract VotingPortalTest is Test {
  address public constant CROSS_CHAIN_CONTROLLER = address(65536 + 123);
  address public constant GOVERNANCE = address(65536 + 1234);
  address public constant VOTING_MACHINE = address(65536 + 12345);
  uint128 public constant GAS_LIMIT = 600000;

  uint256 public VOTING_MACHINE_CHAIN_ID;

  VotingPortal public votingPortal;

  event GasLimitUpdated(
    uint256 indexed gasLimit,
    IVotingPortal.MessageType indexed messageType
  );
  event VoteMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    bytes message,
    bytes reason
  );
  event StartVotingGasLimitUpdated(uint128 gasLimit);

  function setUp() public {
    VOTING_MACHINE_CHAIN_ID = ChainIds.POLYGON;
    votingPortal = new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      GOVERNANCE,
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      GAS_LIMIT,
      address(this)
    );
  }

  function testContractCreationWhenInvalidCCC() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_PORTAL_CROSS_CHAIN_CONTROLLER));
    votingPortal = new VotingPortal(
      address(0),
      GOVERNANCE,
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      GAS_LIMIT,
      address(this)
    );
  }

  function testContractCreationWhenInvalidOwner() public {
    vm.expectRevert(bytes((abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)))));
    votingPortal = new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      GOVERNANCE,
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      GAS_LIMIT,
      address(0)
    );
  }

  function testContractCreationWhenInvalidGovernance() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_PORTAL_GOVERNANCE));
    votingPortal = new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      address(0),
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      GAS_LIMIT,
      address(this)
    );
  }

  function testContractCreationWhenInvalidGasConfig() public {
    new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      GOVERNANCE,
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      0,
      address(this)
    );
  }

  function testContractCreationWhenInvalidVotingMachine() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_PORTAL_VOTING_MACHINE));
    votingPortal = new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      GOVERNANCE,
      address(0),
      VOTING_MACHINE_CHAIN_ID,
      GAS_LIMIT,
      address(this)
    );
  }

  function testContractCreationWhenInvalidVotingMachineChainId() public {
    vm.expectRevert(bytes(Errors.INVALID_VOTING_MACHINE_CHAIN_ID));
    votingPortal = new VotingPortal(
      CROSS_CHAIN_CONTROLLER,
      GOVERNANCE,
      VOTING_MACHINE,
      0,
      GAS_LIMIT,
      address(this)
    );
  }

  function testUpdateGasLimit(uint128 newStartVotingGasLimit) public {
    vm.expectEmit(true, false, false, true);
    emit StartVotingGasLimitUpdated(newStartVotingGasLimit);
    votingPortal.setStartVotingGasLimit(newStartVotingGasLimit);
    assertEq(votingPortal.getStartVotingGasLimit(), newStartVotingGasLimit);
  }

  function testUpdateGasLimitWhenNotOwner(
    uint128 newGasLimit,
    address randomDude
  ) public {
    vm.assume(randomDude != votingPortal.owner());
    vm.startPrank(randomDude);

    vm.expectRevert(bytes(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, randomDude)));
    votingPortal.setStartVotingGasLimit(newGasLimit);
    vm.stopPrank();
  }

  function testForwardStartVotingMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) public {
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      IVotingPortal.MessageType.Proposal,
      message
    );

    vm.mockCall(
      CROSS_CHAIN_CONTROLLER,
      abi.encodeWithSelector(ICrossChainForwarder.forwardMessage.selector),
      abi.encode(bytes32(0), bytes32(0))
    );
    vm.expectCall(
      CROSS_CHAIN_CONTROLLER,
      0,
      abi.encodeWithSelector(
        ICrossChainForwarder.forwardMessage.selector,
        VOTING_MACHINE_CHAIN_ID,
        VOTING_MACHINE,
        GAS_LIMIT,
        messageWithType
      )
    );
    hoax(GOVERNANCE);
    votingPortal.forwardStartVotingMessage(
      proposalId,
      blockHash,
      votingDuration
    );
  }

  function testForwardStartVotingMessageWhenNotGovernance(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_GOVERNANCE));
    votingPortal.forwardStartVotingMessage(
      proposalId,
      blockHash,
      votingDuration
    );
  }

  function testReceiveCrossChainMessage(
    uint256 proposalId,
    uint128 forVotes,
    uint128 againstVotes
  ) public {
    bytes memory message = abi.encode(proposalId, forVotes, againstVotes);
    bytes memory reason;
    hoax(CROSS_CHAIN_CONTROLLER);
    vm.mockCall(
      GOVERNANCE,
      abi.encodeWithSelector(IGovernanceCore.queueProposal.selector),
      abi.encode()
    );
    vm.expectCall(
      GOVERNANCE,
      abi.encodeWithSelector(
        IGovernanceCore.queueProposal.selector,
        proposalId,
        forVotes,
        againstVotes
      )
    );
    vm.expectEmit(true, true, true, true);
    emit VoteMessageReceived(
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      true,
      message,
      reason
    );
    votingPortal.receiveCrossChainMessage(
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectMessage() public {
    uint256 proposalId = 0;
    bytes memory message = abi.encode(proposalId);
    bytes memory reason;
    hoax(CROSS_CHAIN_CONTROLLER);

    vm.expectEmit(true, true, true, true);
    emit VoteMessageReceived(
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      false,
      message,
      reason
    );
    votingPortal.receiveCrossChainMessage(
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectOriginator() public {
    bytes memory message = abi.encode();

    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingPortal.receiveCrossChainMessage(
      address(1),
      VOTING_MACHINE_CHAIN_ID,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectChainId() public {
    bytes memory message = abi.encode();
    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingPortal.receiveCrossChainMessage(
      VOTING_MACHINE,
      ChainIds.AVALANCHE,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectCaller(
    address randomDude
  ) public {
    vm.assume(randomDude != votingPortal.CROSS_CHAIN_CONTROLLER());
    bytes memory message = abi.encode();
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    votingPortal.receiveCrossChainMessage(
      VOTING_MACHINE,
      VOTING_MACHINE_CHAIN_ID,
      message
    );
  }
}
