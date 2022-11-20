import D_SwylClub from './D_SwylClub';
import D_SwylDonation from './D_SwylDonation';
import D_SwylERC721 from './D_SwylERC721';
import D_SwylERC1155 from './D_SwylERC1155';
import D_SwylMatketplace from './D_SwylMatketplace';

const main = async () => {
  await D_SwylClub();
  await D_SwylDonation();
  await D_SwylERC721();
  await D_SwylERC1155();
  await D_SwylMatketplace();
};

main().catch((e: any) => {
  console.error(e);
  process.exitCode = 1;
});
