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

contract Polygon_testnet is BaseRegisterPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
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
      target: 0xEE14C29CE6942225F6acf192fd71112156249B3e,
      withDelegateCall: true,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      value: 0,
      signature: 'execute()',
      callData: ''
    });

    return actions;
  }
}

contract Zksync_testnet is BaseRegisterPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZK_SYNC_SEPOLIA;
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
      target: 0xa8ecDdD3e8beB59efD45b9e152898c6a90baA3d0,
      withDelegateCall: true,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      value: 0,
      signature: 'execute()',
      callData: ''
    });

    return actions;
  }
}
