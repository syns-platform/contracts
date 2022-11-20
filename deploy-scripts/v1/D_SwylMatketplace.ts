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
  SWYL_NFT_SERVICE_RECIPIENT,
  SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS,
} from '../../utils/constants';
import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';

/**
 * @dev deploy SwylClub smart contract
 */
const D_SwylMatketplace = async () => {
  console.log(`Start deploying SwylMarketplace...`);
  // prepare SwylMarketplace SC
  const SwylMarketplace = await ethers.getContractFactory('SwylMarketplace');
  // asyncly deploy SwylMarketplace SC
  const swylMarketplace = await SwylMarketplace.deploy(
    NAVTIVE_TOKEN_WRAPPER,
    SWYL_NFT_SERVICE_RECIPIENT,
    SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS
  );
  await swylMarketplace.deployed();
  console.log(
    `SwylMarketplace deployed to the address: ${swylMarketplace.address}`
  );

  // export contract artifacts to client folder
  exportArtifactsToClient(swylMarketplace, 'SwylMarketplace');
};

export default D_SwylMatketplace;
