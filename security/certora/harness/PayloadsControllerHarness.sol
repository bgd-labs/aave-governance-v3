
pragma solidity ^0.8.8;

import {PayloadsControllerUtils} from '../../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {IPayloadsControllerCore, PayloadsControllerUtils} from '../../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';


import {PayloadsController} from '../../../src/contracts/payloads/PayloadsController.sol';

contract PayloadsControllerHarness is PayloadsController {
  
constructor(
    address crossChainController,
    address messageOriginator,
    uint256 originChainId
  ) PayloadsController (crossChainController,messageOriginator,originChainId) {}



  function getPayloadFieldsById(uint40 payloadId) external view 
  returns (address,PayloadsControllerUtils.AccessControl,PayloadState,uint40,uint40,uint40,uint40,uint40,uint40,uint40)
  {
    Payload memory payload = _payloads[payloadId];
    
    return  (payload.creator, payload.maximumAccessLevelRequired, payload.state, 
    payload.createdAt, payload.queuedAt, payload.executedAt, payload.cancelledAt, 
    payload.expirationTime, payload.delay, payload.gracePeriod);
  }

  function getCreator(uint40 payloadId) external view returns (address){
    return _payloads[payloadId].creator;
  }

  function getExpirationTime(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].expirationTime;
  }

  function getPayloadGracePeriod(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].gracePeriod;
  }

  function getPayloadDelay(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].delay;
  }

  function getPayloadCreatedAt(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].createdAt;
  }

  function getPayloadQueuedAt(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].queuedAt;
  }

  function getPayloadExecutedAt(uint40 payloadId) external view returns (uint40){
    return _payloads[payloadId].executedAt;
  }

function getActionsLength(uint40 payloadId) external view returns (uint256 length) {
    return _payloads[payloadId].actions.length;
  }

function getAction(uint40 payloadId, uint256 actionIndex) external view
                        returns (ExecutionAction memory action) {
    return (_payloads[payloadId].actions[actionIndex]);
  }


function getActionFixedSizeFields(uint40 payloadId, uint256 actionIndex) external view
                        returns (address, bool, PayloadsControllerUtils.AccessControl, uint256) {
    return (_payloads[payloadId].actions[actionIndex].target,
    _payloads[payloadId].actions[actionIndex].withDelegateCall,
    _payloads[payloadId].actions[actionIndex].accessLevel,
    _payloads[payloadId].actions[actionIndex].value);
  }

// function getActionAccessLevel(uint40 payloadId, uint256 actionIndex) external view
//                         returns (PayloadsControllerUtils.AccessControl) {
//     return _payloads[payloadId].actions[actionIndex].accessLevel;
//   }

function getActionAccessLevel(uint40 payloadId, uint256 actionIndex) external view returns (PayloadsControllerUtils.AccessControl) {
    return (_payloads[payloadId].actions[actionIndex].accessLevel);
  }

function getActionSignature(uint40 payloadId, uint256 actionIndex) external view returns (string memory) {
    return (_payloads[payloadId].actions[actionIndex].signature);
  }
function getActionCallData(uint40 payloadId, uint256 actionIndex) external view returns (bytes memory) {
    return (_payloads[payloadId].actions[actionIndex].callData);
  }

function getMaximumAccessLevelRequired(uint40 payloadId) external view returns (PayloadsControllerUtils.AccessControl level) {
    return _payloads[payloadId].maximumAccessLevelRequired;
  }


function compare(string memory str1, string memory str2) external pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

function compare(bytes memory b1, bytes memory b2) external pure returns (bool) {
        return keccak256(abi.encodePacked(b1)) == keccak256(abi.encodePacked(b2));
    }

    function getPayloadStateVariable(uint40 payloadId) external view returns (PayloadState) {
         return _payloads[payloadId].state;
    }

  /**
   * @notice method to encode a message, so it could be sent to the governance chain
   * @param payloadId field 1
   * @param accessLevel field 2
   * @param proposalVoteActivationTimestamp field 3 
   * @return message encoded message
   */
function encodeMessage(uint40 payloadId, PayloadsControllerUtils.AccessControl accessLevel, uint40 proposalVoteActivationTimestamp)
    external pure returns (bytes memory)
  {
    bytes memory message = abi.encode(payloadId, accessLevel, proposalVoteActivationTimestamp);
    return message;
  }

}

