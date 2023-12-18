# Aave Governance V3 Properties

Only one Governance must exist on the system (Ethereum mainnet), while multiple VotingMachines and PayloadsControllers can coexist (Ethereum mainnet and other chains).


## Governance
- Proposal IDs are consecutive and incremental.
- Every proposal should contain at least one payload.
- If a voting portal gets invalidated during the proposal life cycle, the proposal should not transition to any state apart from Cancelled, Expired, and Failed.
- If the proposer's proposition power goes below the minimum required threshold, the proposal should not go to any state apart from Failed or Canceled.
- No further state transitions are possible if `proposal.state > 3`.
- `proposal.state` can't decrease.
- It should be impossible to do more than 1 state transition per proposal per block,
  except:
  - Cancellation because of the proposition power change.
  - Cancellation after proposal creation by creator.
  - Proposal execution after proposal queuing if `COOLDOWN_PERIOD` is 0.
- Only the owner can set the voting power strategy and voting config.
- When invalidating voting config, proposal can not be queued
- Guardian can cancel proposals with `proposal.state < 4`
- The following proposal parameters can only be set once, at proposal creation:
  creator, accessLevel, votingPortal, creationTime, ipfsHash, payloads.
- The following proposal parameters can only be set once, during voting activation:
  votingActivationTime, snapshotBlockHash, votingDuration.
- Only a valid voting portal can queue a proposal and only if this is in `Active` state.
- A proposal can be executed only in `Queued` state, after passing the cooldown period.
- The Governance Core system shouldn’t know anything about the voting procedure. It only expects a whitelisted entity to submit voting results about a specific proposal id.
- The Governance Core system shouldn’t know anything about final execution. From its perspective, execution is sent to a Portal.
## VotingMachine
- Proposal Ids must match with the existing Proposal Ids generated in governance core (so they can be not sequential)
- `proposal.state` can't decrease
- A voter can only vote once, no matter which assets he uses.
- Nobody can vote on behalf of anybody else unless there is a signature or a smart-contracts verified intent from the originator (voting via portal on governance core) of the voting power (holder of balance or voting power delegation).
- Once a block hash from a specific chain is stored on the DataWarehouse, this is immutable.
- It is not possible to vote on a VotingMachine if no block hash has been set on the configuration of the proposal vote configuration.
- It is not possible to vote on a VotingMachine if no global storage roots have been stored on the DataWarehouse. (For all the tokens used on the voting strategy)

## PayloadsController
- Payloads Ids are consecutive
- A payload must have at least one action
- The following Payload params can only be set once during payload creation:
  - ipfsHash
  - action[]: target, withDelegateCall, accessLevel, value, signature, callData
- An Executor must exist of the max level required for the payload actions (action must be able to be executed)
- A Payload can only be executed when in `queued` state and time lock has finished and before the `grace period` has passed.
- A Payload can never be executed if it has not been queued before the `EXPIRATION_DELAY` defined.
- The Guardian can cancel a Payload if it has not been executed
- Payload State can’t decrease
- No further state transitions are possible if `proposal.state > 3`
