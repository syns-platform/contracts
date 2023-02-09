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
 * @dev deploy SynsDonation smart contract
 */
const D_SynsDonation = async () => {
  console.log(`Start deploying SynsDonation...`);

  // prepare SynsDonation SC
  const SynsDonation = await ethers.getContractFactory('SynsDonation');

  // asyncly deploy SynsDonation SC
  const synsDonation = await SynsDonation.deploy(NAVTIVE_TOKEN_WRAPPER);
  await synsDonation.deployed();
  console.log(`SynsDonation deployed to the address: ${synsDonation.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(synsDonation, 'SynsDonation');
};

export default D_SynsDonation;
