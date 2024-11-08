// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithPayloadsManager {
  /**
   * @dev Emitted when the payload manager gets updated.
   * @param oldPayloadsManager The address of the old payload manager.
   * @param newPayloadsManager The address of the new payload manager.
   */
  event PayloadsManagerUpdated(address oldPayloadsManager, address newPayloadsManager);

  /**
   * @dev get payload manager address;
   */
  function payloadsManager() external view returns(address);

  /**
   * @dev method to update payload manager.
   * @param newPayloadsManager The new payload manager address.
   */
  function updatePayloadsManager(address newPayloadsManager) external;
}