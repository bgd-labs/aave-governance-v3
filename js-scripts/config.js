export const Tokens = {
  STK_AAVE_TOKEN: "0xA4FDAbdE9eF3045F0dcF9221bab436B784B7e42D",
  A_AAVE_TOKEN: "0x7d9EB767eEc260d1bCe8C518276a894aE5535F04",
  AAVE_TOKEN: "0x64033B2270fd9D6bbFc35736d2aC812942cE75fE",
  GOVERNANCE_REPRESENTATIVE: "0x84b3FE5eD74caC496BcB58d448A7c83c523F6E0E",
};
export const CONFIG = {
  ETH_TESTNET_BLOCK: 4196648,
  PROPOSAL_CREATOR: "0x6D603081563784dB3f83ef1F65Cc389D94365Ac9",
  VOTER: "0x6D603081563784dB3f83ef1F65Cc389D94365Ac9",
  slots: {
    [Tokens.STK_AAVE_TOKEN]: {
      balance: 0,
      exchangeRate: 81,
    },
    [Tokens.A_AAVE_TOKEN]: {
      balance: 52,
      delegation: 64,
    },
    [Tokens.AAVE_TOKEN]: {
      balance: 0,
    },
    [Tokens.GOVERNANCE_REPRESENTATIVE]: {
      representatives: 9,
    },
  },
};
