/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Honor: Thirdweb & Openzeppeline
*/

import { HardhatUserConfig } from 'hardhat/types';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-etherscan';
import 'dotenv/config';

/** @notice constants */
const HEDERA_TESTNET_RPC_URL = process.env.HEDERA_TESTNET_RPC_URL;
const SYNS_DEPLOYER_PRIVATE_KEY = process.env.SYNS_DEPLOYER_PRIVATE_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: 'hedera_testnet',
  solidity: {
    version: '0.8.11',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {},
    hedera_testnet: {
      url: HEDERA_TESTNET_RPC_URL,
      accounts: [SYNS_DEPLOYER_PRIVATE_KEY as string],
      chainId: 296,
    },
  },
};

export default config;
