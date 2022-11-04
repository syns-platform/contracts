<p align="center">
<br />
<h1 align="center">SWYL - Support Who You Love - v1.0 </h1>
<h4 align="center"></h4>
</p>

## Overview

Collection of smart contracts written in [Solidity](https://soliditylang.org/) that powers ****`Swyl's blockchain logic`**** on the [Polygon blockchain](https://polygon.technology/matic-token/).


## Hightlighted features
- [SwylERC721](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylERC721.sol) - includes all the NFT industry standards from [ERC721A](https://www.erc721a.org) & [@Thirdweb/ERC721Base](https://github.com/thirdweb-dev/contracts/blob/main/contracts/base/ERC721Base.sol) PLUS `Swyl's ERC721 logic`.


- [SwylERC1155](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylERC1155.sol) -  includes all the NFT industry standards from [ERC1155](https://ethereum.org/en/developers/docs/standards/tokens/erc-1155/) PLUS `Swyl's ERC1155 logic`.

- [SwylDonation](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylDonation.sol) - allows any user to make a donation with an arbitrary amount of crypto currency to another user on the platform. All the transactions are transparently recorded on the blockchain.

- [SwylMarketPlace](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylMarketplace.sol) - a combination of many safe, gas optimizing and well-tested features from the [@Thirdweb/Marketplace](https://github.com/thirdweb-dev/contracts/blob/main/contracts/marketplace/Marketplace.sol) and a plethora of `Swyl's complex marketplace logic`, SwylMarketplace is able to:
   - allows a token owner create/update/cancel an NFT listing for sale on the blockchain
   - on behalf of the token owner, safely allows buy and transfer NFT transaction to take place automatically without the presence of the seller. After a sale, automatically transfer the listing price from buy's to seller's crypto wallet address
   - automatically calculates and transfers [royties](https://www.nftgators.com/nft-royalties-explained/) to original creator

- [SwylClub](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylClub.sol) - most honored out of the five contracts, powers all the complex Swyl membership logic. SwylClub is able to:
   - allows a possible club owner to create a `SwylClub` which then can be added with a number of SwylTier (i.e. membership plans). In each `SwylTier`, user can config their own desired amount of `Tier Fee`, arbitary amount of `Tier Limit` to limit the members in a `SwylTier`, update the metadata at any time
   - allows club owners to easily keep track of the total members and the total active members in each `SwylTier`, periodically make a request to `wipe off` inactive members, 
   - allows a possible subscriber to subscribe/unsubscribe to any `SwylTier` in any `SwylClub` on the platform. `SwylClub` automatically calculates next payment in 30 days for the followers, records the very first date they started following the Club, increases the `SwylRoyaltyStars` (i.e. an Swyl honor system based on how long a follower follow a club)


## Building the project

```bash
npm run build
# or
yarn build
```

to compile your contracts. This will also detect the [Contracts Extensions Docs](https://portal.thirdweb.com/thirdweb-deploy/contract-extensions) detected on the contract.

## Deploying Contracts

```bash
npm run deploy
# or
yarn deploy
```

## Releasing Contracts

```bash
npm run release
# or
yarn release
```

## Resources / Honors

- [Thirdweb](https://thirdweb.com/)
- [OpenZeppelin](https://www.openzeppelin.com/)


<!-- implements the [@Thirdweb](https://thirdweb.com/)/[ERC721Base](https://github.com/thirdweb-dev/contracts/blob/main/contracts/base/ERC721Base.sol) NFT standard, along with the [ERC721A](https://www.erc721a.org/) optimization. `SwylERC721`
implements the [@Thirdweb](https://thirdweb.com/)/[ERC1155Base](https://github.com/logann131/contracts/blob/main/contracts/base/ERC1155Base.sol) NFT standard. `SwylERC1155`-->

