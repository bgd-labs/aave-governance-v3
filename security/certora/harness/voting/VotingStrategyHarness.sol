pragma solidity ^0.8.0;

import {VotingStrategy} from '../../../src/contracts/voting/VotingStrategy.sol';


/**
 * @title VotingStrategyHarness
 * Needed for `hasRequiredRoots`.
 */
contract VotingStrategyHarness is VotingStrategy {
  constructor(address dataWarehouse) VotingStrategy (dataWarehouse) {
  }

  // Converts `hasRequiredRoots` to a function that returns boolean
  function is_hasRequiredRoots(bytes32 blockHash) external view returns (bool) {
    bool is_ok;
    try this.hasRequiredRoots(blockHash) {
      is_ok = true;
    } catch (bytes memory) {}
    return is_ok;
  }

  // Just the length of the array
  function getVotingAssetListLength() external view returns (uint256) {
    return this.getVotingAssetList().length;
  }
}
