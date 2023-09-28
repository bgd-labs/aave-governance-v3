
pragma solidity ^0.8.8;

import {Governance} from '../../src/contracts/Governance.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {IGovernanceCore, EnumerableSet} from '../../src/interfaces/IGovernanceCore.sol';


contract GovernanceHarness is Governance {
  using EnumerableSet for EnumerableSet.AddressSet;
  

  constructor(
    address crossChainController,
    uint256 coolDownPeriod,
    address cancellationFeeCollector
  )
    Governance(crossChainController, coolDownPeriod, cancellationFeeCollector){}

  function getPayloadLength(uint256 proposalId) external view returns (uint256) {
    return _proposals[proposalId].payloads.length;
  }

  function getProposalStateVariable(uint256 proposalId) external view returns (State) {
    return _proposals[proposalId].state;
  }
  function getProposalVotingPortal(uint256 proposalId) external view returns (address) {
    return _proposals[proposalId].votingPortal;
  }

  function getProposalAccessLevel(uint256 proposalId) external view returns (PayloadsControllerUtils.AccessControl) {
    return _proposals[proposalId].accessLevel;
  }

  function getProposalCreator(uint256 proposalId) external view returns (address) {
    return _proposals[proposalId].creator;}

  function getProposalVotingDuration(uint256 proposalId) external view returns (uint24) {
    return _proposals[proposalId].votingDuration;}

  function getProposalCreationTime(uint256 proposalId) external view returns (uint40) {
    return _proposals[proposalId].creationTime;}

  function getProposalIpfsHash(uint256 proposalId) external view returns (bytes32) {
    return _proposals[proposalId].ipfsHash;}

  function getProposalVotingActivationTime(uint256 proposalId) external view returns (uint40) {
    return _proposals[proposalId].votingActivationTime;}

  function getProposalSnapshotBlockHash(uint256 proposalId) external view returns (bytes32) {
    return _proposals[proposalId].snapshotBlockHash;}

  function getProposalCancellationFee(uint256 proposalId) external view returns (uint256) {
    return _proposals[proposalId].cancellationFee;}

  function getPayloadChain(uint256 proposalId, uint256 payloadID) external view returns (uint256) {
    return _proposals[proposalId].payloads[payloadID].chain;
  }

  function getPayloadAccessLevel(uint256 proposalId, uint256 payloadID) external view returns (PayloadsControllerUtils.AccessControl) {
    return _proposals[proposalId].payloads[payloadID].accessLevel;
  }
  function getPayloadPayloadsController(uint256 proposalId, uint256 payloadID) external view returns (address) {
    return _proposals[proposalId].payloads[payloadID].payloadsController;
  }

  function getPayloadPayloadId(uint256 proposalId, uint256 payloadID) external view returns (uint40) {
    return _proposals[proposalId].payloads[payloadID].payloadId;
  }

  function getProposalCount() external view returns (uint256) {
    return _proposalsCount;
  }

  function isRepresentativeOfVoter(
    address voter,
    address representative,
    uint256 chainId
  ) external view returns (bool) {
    return _votersRepresented[representative][chainId].contains(voter);
  }

  function updateSingleRepresentativeForChain(
    address representative, uint256 chainId0) external {

    RepresentativeInput memory representativeInput;
    representativeInput.representative = representative;
    representativeInput.chainId = chainId0;
    
    RepresentativeInput[] memory representatives = new RepresentativeInput[](1);
    representatives[0] = representativeInput;
    

    //todo: call as external
    //updateRepresentativesForChain(representatives);

      uint256 i = 0;
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

  
  /**
   * @notice Returns the size of the voters set of a given representative
   */
    function getRepresentedVotersSize(
    address representative,
    uint256 chainId
  ) external view returns (uint256) {
    return _votersRepresented[representative][chainId].values().length;
  }



}
