// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'aave-delivery-infrastructure/contracts/libs/EncodingUtils.sol';
import 'aave-delivery-infrastructure/contracts/libs/ChainIds.sol';
import '../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';
import {PayloadsControllerUtils} from '../src/contracts/payloads/PayloadsControllerUtils.sol';

contract MessageSizesTest is Test {
  address public constant ORIGIN = address(123);
  address public constant DESTINATION = address(1234);
  address public constant VOTER = address(12345);
  address public constant PAYLOADS_CONTROLLER = address(123456);
  uint256 public constant ORIGIN_CHAIN_ID = ChainIds.ETHEREUM;
  uint256 public constant DESTINATION_CHAIN_ID = ChainIds.POLYGON;
  uint256 public constant PROPOSAL_ID = 0;
  uint40 public constant PAYLOAD_ID = 0;
  uint256 public constant NONCE = 0;

  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
  address public constant A_AAVE = 0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9;
  uint128 public constant BASE_BALANCE_SLOT = 0;
  uint128 public constant A_AAVE_BASE_BALANCE_SLOT = 52;
  uint128 public constant A_AAVE_DELEGATED_STATE_SLOT = 64;

  function setUp() public {}

  function testProposalVoteMessage() public {
    bytes32 blockHash = blockhash(block.number - 1);
    uint24 votingDuration = 3 days;
    bytes memory message = abi.encode(PROPOSAL_ID, blockHash, votingDuration);

    //    console.log('Proposal--------------------');
    //    _cccEncode(message);
  }

  function testExecuteProposalMessage() public {
    uint40 proposalVoteActivationTimestamp = 123;
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: DESTINATION_CHAIN_ID,
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        payloadsController: PAYLOADS_CONTROLLER,
        payloadId: PAYLOAD_ID
      });

    bytes memory message = abi.encode(
      payload.payloadId,
      payload.accessLevel,
      proposalVoteActivationTimestamp
    );

    //    console.log('ExecuteProposal--------------------');
    //    _cccEncode(message);
  }

  function testQueueVoteResultsMessage() public {
    uint256 forVotes = 3_000_000 ether;
    uint256 againstVotes = 1_231_000 ether;

    bytes memory message = abi.encode(PROPOSAL_ID, forVotes, againstVotes);

    //    console.log('QueueVote--------------------');
    //    _cccEncode(message);
  }

  function _cccEncode(bytes memory message) internal {
    // envelope
    Envelope memory envelope = Envelope({
      nonce: NONCE,
      origin: ORIGIN,
      destination: DESTINATION,
      originChainId: ORIGIN_CHAIN_ID,
      destinationChainId: DESTINATION_CHAIN_ID,
      message: message
    });
    EncodedEnvelope memory encodedEnvelope = EnvelopeUtils.encode(envelope);

    // transaction
    Transaction memory transaction = Transaction({
      nonce: 0,
      encodedEnvelope: encodedEnvelope.data
    });
    EncodedTransaction memory encodedTransaction = TransactionUtils.encode(
      transaction
    );
    console.logBytes(encodedTransaction.data);
    console.log('bytes length: ', encodedTransaction.data.length);
    console.log('--------------------');
  }
}
