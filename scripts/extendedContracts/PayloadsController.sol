// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PayloadsController} from '../../src/contracts/payloads/PayloadsController.sol';
import {IPayloadsControllerCore, PayloadsControllerCore} from '../../src/contracts/payloads/PayloadsControllerCore.sol';

contract PayloadsControllerExtended is PayloadsController {
  /**
   * @param crossChainController address of the CrossChainController contract deployed on current chain. This contract
            is the one responsible to send here the voting configurations once they are bridged.
   * @param messageOriginator address of the contract where the message originates (mainnet governance)
   * @param originChainId the id of the network where the messages originate from
   */
  constructor(
    address crossChainController,
    address messageOriginator,
    uint256 originChainId
  )
    PayloadsController(crossChainController, messageOriginator, originChainId)
  {}

  /// @inheritdoc IPayloadsControllerCore
  function MIN_EXECUTION_DELAY()
    public
    pure
    override(IPayloadsControllerCore, PayloadsControllerCore)
    returns (uint40)
  {
    return 0;
  }

  /// @inheritdoc IPayloadsControllerCore
  function MAX_EXECUTION_DELAY()
    public
    pure
    override(IPayloadsControllerCore, PayloadsControllerCore)
    returns (uint40)
  {
    return 10 days;
  }
}
