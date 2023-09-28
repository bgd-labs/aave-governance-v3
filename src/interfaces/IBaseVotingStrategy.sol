// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseVotingStrategy
 * @author BGD Labs
 * @notice interface containing the objects, events and method definitions of the BaseVotingStrategy contract
 */
interface IBaseVotingStrategy {
  /**
   * @notice object storing the information of the asset used for the voting strategy
   * @param storageSlots list of slots for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   */
  struct VotingAssetConfig {
    uint128[] storageSlots;
  }

  /**
   * @notice emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlots array of storage positions of the balance mapping
   */
  event VotingAssetAdd(address indexed asset, uint128[] storageSlots);

  /**
   * @notice method to get the AAVE token address
   * @return AAVE token contract address
   */
  function AAVE() external view returns (address);

  /**
   * @notice method to get the A_AAVE token address
   * @return A_AAVE token contract address
   */
  function A_AAVE() external view returns (address);

  /**
   * @notice method to get the stkAAVE token address
   * @return stkAAVE token contract address
   */
  function STK_AAVE() external view returns (address);

  /**
   * @notice method to get the slot of the balance of the AAVE and stkAAVE
   * @return AAVE and stkAAVE base balance slot
   */
  function BASE_BALANCE_SLOT() external view returns (uint128);

  /**
   * @notice method to get the slot of the balance of the AAVE aToken
   * @return AAVE aToken base balance slot
   */
  function A_AAVE_BASE_BALANCE_SLOT() external view returns (uint128);

  /**
   * @notice method to get the slot of the AAVE aToken delegation state
   * @return AAVE aToken delegation state slot
   */
  function A_AAVE_DELEGATED_STATE_SLOT() external view returns (uint128);

  /**
   * @notice method to check if a token and slot combination is accepted
   * @param token address of the token to check
   * @param slot number of the token slot
   * @return flag indicating if the token slot is accepted
   */
  function isTokenSlotAccepted(
    address token,
    uint128 slot
  ) external view returns (bool);

  /**
   * @notice method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @notice method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the list of storage slots
   */
  function getVotingAssetConfig(
    address asset
  ) external view returns (VotingAssetConfig memory);
}
