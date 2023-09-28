import { getProofsJson, saveJson } from "./fileSystem.js";
import { CONFIG, Tokens } from "./config.js";
import { ethers, providers, utils, BigNumber, constants } from "ethers";
import {
  formatToProofRLP,
  getExtendedBlock,
  getProof,
  getSolidityStorageSlotBytes,
  getSolidityTwoLevelStorageSlotHash,
  prepareBLockRLP,
} from "./utils.js";
import { hexZeroPad } from "ethers/lib/utils.js";
import "dotenv/config";
import stringify from "json-stable-stringify";
import ERC20WithDelegation from "./abis/ERC20WithDelegation.json" assert { type: "json" };

const generateRoots = async (
  provider,
  token,
  baseBalanceSlotRaw,
  extraSlotRaw,
  name
) => {
  const proofsJson = getProofsJson();

  if (!proofsJson[name]) {
    proofsJson[name] = {
      token: token,
    };
  }

  // calculate blockHeaderRLP
  const blockData = await getExtendedBlock(provider, CONFIG.ETH_TESTNET_BLOCK);
  const blockHeaderRLP = prepareBLockRLP(blockData);

  proofsJson.blockHash = blockData.hash;
  proofsJson[name].blockHeaderRLP = blockHeaderRLP;

  // calculate slots
  const slots = [];
  if (baseBalanceSlotRaw != null) {
    proofsJson[name].baseBalanceSlotRaw = baseBalanceSlotRaw;
    const balanceSlot = hexZeroPad(utils.hexlify(baseBalanceSlotRaw), 32);

    slots.push(balanceSlot);
    proofsJson[name].baseBalanceSlot = balanceSlot;
  }
  if (token === Tokens.A_AAVE_TOKEN) {
    proofsJson[name].delegationSlotRaw = extraSlotRaw;
    const delegationSlot = hexZeroPad(utils.hexlify(extraSlotRaw), 32);
    slots.push(delegationSlot);
    proofsJson[name].delegationBalanceSlot = delegationSlot;
  } else if (token === Tokens.STK_AAVE_TOKEN) {
    proofsJson[name].exchangeRateSlotRaw = extraSlotRaw;
    const stkAaveExchangeRateSlot = hexZeroPad(utils.hexlify(extraSlotRaw), 32);
    slots.push(stkAaveExchangeRateSlot);
    proofsJson[name].stkAaveExchangeRateSlot = stkAaveExchangeRateSlot;
  } else if (token === Tokens.GOVERNANCE_REPRESENTATIVE) {
    proofsJson[name].representativesSlotRaw = extraSlotRaw;
    const representativeSlot = hexZeroPad(utils.hexlify(extraSlotRaw), 32);
    slots.push(representativeSlot);
    proofsJson[name].representativesSlot = representativeSlot;
  }

  // get account state proof rlp
  const rawAccountProofData = await getProof(
    provider,
    token,
    slots,
    CONFIG.ETH_TESTNET_BLOCK
  );

  const accountStateProofRLP = formatToProofRLP(
    rawAccountProofData.accountProof
  );
  proofsJson[name].accountStateProofRLP = accountStateProofRLP;

  saveJson(stringify(proofsJson));
};

const generateProofs = async (
  provider,
  token,
  rawSlot,
  slot,
  proofName,
  name
) => {
  const proofsJson = getProofsJson();

  if (!proofsJson[name]) {
    proofsJson[name] = {
      token: token,
    };
  }

  const rawAccountProofData = await getProof(
    provider,
    token,
    [slot],
    CONFIG.ETH_TESTNET_BLOCK
  );

  const storageProofRlp = formatToProofRLP(
    rawAccountProofData.storageProof[0].proof
  );

  proofsJson[name][proofName] = storageProofRlp;

  saveJson(stringify(proofsJson));
};

const generateProofsVoterSlot = async (
  provider,
  token,
  rawSlot,
  voter,
  proofName,
  name
) => {
  const hexSlot = utils.hexlify(rawSlot);
  const slot = getSolidityStorageSlotBytes(hexSlot, voter);
  return generateProofs(provider, token, rawSlot, slot, proofName, name);
};

const generateProofsRepresentativeByChain = async (
  provider,
  token,
  rawSlot,
  voter,
  chainId,
  proofName,
  name
) => {
  const hexSlot = utils.hexlify(rawSlot);
  const slot = getSolidityTwoLevelStorageSlotHash(hexSlot, voter, chainId);
  console.log("representative slot: ", slot);
  const proofsJson = getProofsJson();

  if (!proofsJson[name]) {
    proofsJson[name] = {
      token: token,
    };
  }
  const representative = await provider.getStorageAt(token, slot);
  console.log("representative: ", representative);
  proofsJson[name].representativesSlotHash = slot;
  proofsJson[name].representative = representative;
  proofsJson[name].represented = voter;
  proofsJson[name].chainId = chainId;

  saveJson(stringify(proofsJson));

  return generateProofs(provider, token, rawSlot, slot, proofName, name);
};

const generateProofsHexSlot = async (
  provider,
  token,
  rawSlot,
  voter,
  proofName,
  name
) => {
  const hexSlot = utils.hexlify(rawSlot);
  const exchangeRateSlot = hexZeroPad(hexSlot, 32);
  return generateProofs(
    provider,
    token,
    rawSlot,
    exchangeRateSlot,
    proofName,
    name
  );
};

const getVoterBalances = async (provider, token, voter, name) => {
  const proofsJson = getProofsJson();

  if (!proofsJson[name]) {
    throw new Error("Roots and proofs needed for this step");
  }

  const erc20WithDelegation = new ethers.Contract(
    token,
    ERC20WithDelegation,
    provider
  );

  const balance = await erc20WithDelegation.balanceOf(voter);
  const votingPower = await erc20WithDelegation.getPowerCurrent(voter, 0);
  const delegatee = await erc20WithDelegation.getDelegateeByType(voter, 0);

  proofsJson[name].delegating = false;
  console.log("delegatee: ", delegatee);
  if (
    delegatee.toLowerCase() !== voter.toLowerCase() &&
    delegatee !== constants.AddressZero
  ) {
    proofsJson[name].delegating = true;
  }

  const balanceStorageValue = await provider.send("eth_getStorageAt", [
    token,
    getSolidityStorageSlotBytes(
      hexZeroPad(utils.hexlify(proofsJson[name].baseBalanceSlotRaw), 32),
      voter
    ),
    BigNumber.from(CONFIG.ETH_TESTNET_BLOCK).toHexString(),
  ]);

  proofsJson[name].balanceSlotValue = utils.defaultAbiCoder.encode(
    ["uint256"],
    [BigNumber.from(balanceStorageValue).toString()]
  );

  proofsJson[name].balance = utils.defaultAbiCoder.encode(
    ["uint256"],
    [balance.toString()]
  );
  proofsJson[name].votingPower = utils.defaultAbiCoder.encode(
    ["uint256"],
    [votingPower.toString()]
  );

  if (token === Tokens.STK_AAVE_TOKEN) {
    const storageValue = await provider.send("eth_getStorageAt", [
      token,
      proofsJson[name].stkAaveExchangeRateSlot,
      BigNumber.from(CONFIG.ETH_TESTNET_BLOCK).toHexString(),
    ]);
    proofsJson[name].exchangeRate = utils.defaultAbiCoder.encode(
      ["uint256"],
      [BigNumber.from(storageValue).toString()]
    );
  } else if (token === Tokens.A_AAVE_TOKEN) {
    const storageValue = await provider.send("eth_getStorageAt", [
      token,
      getSolidityStorageSlotBytes(
        hexZeroPad(utils.hexlify(proofsJson[name].delegationSlotRaw), 32),
        voter
      ),
      BigNumber.from(CONFIG.ETH_TESTNET_BLOCK).toHexString(),
    ]);
    proofsJson[name].delegationBalanceSlotValue = utils.defaultAbiCoder.encode(
      ["uint256"],
      [BigNumber.from(storageValue).toString()]
    );
  }

  saveJson(stringify(proofsJson));
};

const generateJson = async () => {
  const provider = new providers.StaticJsonRpcProvider(
    process.env.RPC_MAINNET_TESTNET
  );

  // get roots
  await generateRoots(provider, Tokens.AAVE_TOKEN, 0, null, "AAVE");
  await generateRoots(provider, Tokens.A_AAVE_TOKEN, 52, 64, "A_AAVE");
  await generateRoots(provider, Tokens.STK_AAVE_TOKEN, 0, 81, "STK_AAVE");
  await generateRoots(
    provider,
    Tokens.GOVERNANCE_REPRESENTATIVE,
    null,
    9,
    "REPRESENTATIVES"
  );

  // get vote proofs
  await generateProofsVoterSlot(
    provider,
    Tokens.AAVE_TOKEN,
    CONFIG.slots[Tokens.AAVE_TOKEN].balance,
    CONFIG.VOTER,
    "balanceStorageProofRlp",
    "AAVE"
  );
  await generateProofsVoterSlot(
    provider,
    Tokens.A_AAVE_TOKEN,
    CONFIG.slots[Tokens.A_AAVE_TOKEN].balance,
    CONFIG.VOTER,
    "balanceStorageProofRlp",
    "A_AAVE"
  );
  await generateProofsVoterSlot(
    provider,
    Tokens.STK_AAVE_TOKEN,
    CONFIG.slots[Tokens.STK_AAVE_TOKEN].balance,
    CONFIG.VOTER,
    "balanceStorageProofRlp",
    "STK_AAVE"
  );

  // get stk exchange rate
  await generateProofsHexSlot(
    provider,
    Tokens.STK_AAVE_TOKEN,
    CONFIG.slots[Tokens.STK_AAVE_TOKEN].exchangeRate,
    CONFIG.VOTER,
    "stkAaveExchangeRateStorageProofRlp",
    "STK_AAVE"
  );

  // get aToken delegation
  await generateProofsVoterSlot(
    provider,
    Tokens.A_AAVE_TOKEN,
    CONFIG.slots[Tokens.A_AAVE_TOKEN].delegation,
    CONFIG.VOTER,
    "aAaveDelegationStorageProofRlp",
    "A_AAVE"
  );

  await generateProofsRepresentativeByChain(
    provider,
    Tokens.GOVERNANCE_REPRESENTATIVE,
    CONFIG.slots[Tokens.GOVERNANCE_REPRESENTATIVE].representatives,
    CONFIG.VOTER,
    31337, // foundry network id
    "proofOfRepresentative",
    "REPRESENTATIVES"
  );

  await getVoterBalances(provider, Tokens.AAVE_TOKEN, CONFIG.VOTER, "AAVE");
  await getVoterBalances(provider, Tokens.A_AAVE_TOKEN, CONFIG.VOTER, "A_AAVE");
  await getVoterBalances(
    provider,
    Tokens.STK_AAVE_TOKEN,
    CONFIG.VOTER,
    "STK_AAVE"
  );

  const proofsJson = getProofsJson();
  proofsJson.voter = CONFIG.VOTER;
  proofsJson.proposalCreator = CONFIG.PROPOSAL_CREATOR;
  proofsJson.tokens = [
    Tokens.AAVE_TOKEN,
    Tokens.A_AAVE_TOKEN,
    Tokens.STK_AAVE_TOKEN,
  ];
  proofsJson.governance = Tokens.GOVERNANCE_REPRESENTATIVE;

  saveJson(stringify(proofsJson));
};

generateJson().then().catch();
