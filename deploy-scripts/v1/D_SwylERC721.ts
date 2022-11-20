/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';

import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';
import {
  SWYL_NFT_NAME,
  SWYL_NFT_SYMBOL,
  SWYL_NFT_SERVICE_RECIPIENT,
  SWYL_NFT_DEFAULT_ROYALTY_BPS,
} from '../../utils/constants';

/**
 * @dev deploy swylERC721 smart contract
 */
const D_SwylERC721 = async () => {
  console.log(`Start deploying SwylERC721...`);
  // prepare SwylERC721 SC
  const SwylERC721 = await ethers.getContractFactory('SwylERC721');
  // asyncly deploy SwylERC721 SC
  const swylERC721 = await SwylERC721.deploy();
  await swylERC721.deployed();
  console.log(`SwylERC721 deployed to the address: ${swylERC721.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(swylERC721, 'SwylERC721');
};

export default D_SwylERC721;
