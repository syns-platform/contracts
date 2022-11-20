/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';
import { NAVTIVE_TOKEN_WRAPPER } from '../../utils/constants';
import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';

/**
 * @dev deploy SwylDonation smart contract
 */
const D_SwylDonation = async () => {
  console.log(`Start deploying SwylDonation...`);
  // prepare SwylDonation SC
  const SwylDonation = await ethers.getContractFactory('SwylDonation');
  // asyncly deploy SwylDonation SC
  const swylDonation = await SwylDonation.deploy(NAVTIVE_TOKEN_WRAPPER);
  await swylDonation.deployed();
  console.log(`SwylDonation deployed to the address: ${swylDonation.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(swylDonation, 'SwylDonation');
};

export default D_SwylDonation;
