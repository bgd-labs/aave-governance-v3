// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';

abstract contract BaseRegisterPayload is GovBaseScript {
  function getPayloadActions()
    public
    view
    virtual
    returns (IPayloadsControllerCore.ExecutionAction[] memory);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    uint40 payloadId = IPayloadsControllerCore(addresses.payloadsController)
      .createPayload(getPayloadActions());
    console.log('payloadId', payloadId);
  }
}

contract Zksync is BaseRegisterPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }

  function getPayloadActions()
    public
    pure
    override
    returns (IPayloadsControllerCore.ExecutionAction[] memory)
  {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);

    actions[0] = IPayloadsControllerCore.ExecutionAction({
      target: 0x69fEa012548e281B2A02128D69Ef5Ce6e7C53122,
      withDelegateCall: true,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      value: 0,
      signature: 'execute()',
      callData: ''
    });

    return actions;
  }
}
