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
import 'hardhat-gas-reporter';
import 'dotenv/config';

/** @notice constants */
const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL;
const POLYGON_SCAN_API_KEY = process.env.POLYGON_SCAN_API_KEY;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
const SWYL_SERVICE_PRIVATE_KEY = process.env.SWYL_SERVICE_PRIVATE_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: 'mumbai',
  solidity: {
    version: '0.8.11',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {},
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [SWYL_SERVICE_PRIVATE_KEY as string],
      chainId: 80001,
    },
  },
  etherscan: {
    apiKey: POLYGON_SCAN_API_KEY as string,
  },
  gasReporter: {
    enabled: false,
    currency: 'USD',
    coinmarketcap: COINMARKETCAP_API_KEY,
    token: 'ETH',
  },
};

export default config;
