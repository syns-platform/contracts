/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';
import {
  NAVTIVE_TOKEN_WRAPPER,
  SYNS_NFT_SERVICE_RECIPIENT,
  SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS,
} from '../../utils/constants';
import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';

/**
 * @dev deploy SynsClub smart contract
 */
const D_SynsMatketplace = async () => {
  console.log(`Start deploying SynsMarketplace...`);
  // prepare SynsMarketplace SC
  const SynsMarketplace = await ethers.getContractFactory('SynsMarketplace');
  // asyncly deploy SynsMarketplace SC
  const synslMarketplace = await SynsMarketplace.deploy(
    NAVTIVE_TOKEN_WRAPPER,
    SYNS_NFT_SERVICE_RECIPIENT,
    SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS
  );
  await synslMarketplace.deployed();
  console.log(
    `SynsMarketplace deployed to the address: ${synslMarketplace.address}`
  );

  // export contract artifacts to client folder
  exportArtifactsToClient(synslMarketplace, 'SynsMarketplace');
};

export default D_SynsMatketplace;
