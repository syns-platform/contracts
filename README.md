<p align="center">
<br />
<a href="https://github.com/SWYLy/contracts"><img src="https://github.com/SWYLy/materials/blob/master/logo.svg?raw=true" width="150" alt=""/></a>
<h1 align="center">SWYL - Support Who You Love - v1.0 </h1>
<h4 align="center"></h4>
</p>

## Overview

Collection of smart contracts written in [Solidity](https://soliditylang.org/) that powers \***\*`Swyl's blockchain logic`\*\*** on the [Polygon network](https://polygon.technology/matic-token/).

## Hightlighted features

- [SwylERC721](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylERC721.sol) - includes all the standard features of an NFT industry, as defined by the `ERC721 specification` from [OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721), as well as additional custom logic developed by SWYL to automatically set the default royalty fee for new NFTs as soon as they are minted.

* [SwylERC1155](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylERC1155.sol) - includes all the standard features of the NFT industry as defined by the [ERC1155 specification](https://ethereum.org/en/developers/docs/standards/tokens/erc-1155/), as well as additional custom logic developed by SWYL.

* [SwylDonation](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylDonation.sol) - allows any user to make a donation with an arbitrary amount of crypto currency to another user on the platform. All the transactions are transparently recorded on the blockchain.

* [SwylMarketPlace](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylMarketplace.sol) - a combination of many safe, gas optimizing and well-tested features from the [@Thirdweb/Marketplace](https://github.com/thirdweb-dev/contracts/blob/main/contracts/marketplace/Marketplace.sol) and a plethora of `Swyl's complex marketplace logic`, SwylMarketplace is able to:

  - allows a token owner create/update/cancel an NFT listing for sale on the blockchain
  - on behalf of the token owner, safely allows buy and transfer NFT transaction to take place automatically without the presence of the seller. After a sale, automatically transfer the listing price from buy's to seller's crypto wallet address
  - automatically calculates and transfers [royties](https://www.nftgators.com/nft-royalties-explained/) to original creator

* [SwylClub](https://github.com/SWYLy/contracts/blob/main/contracts/v1/SwylClub.sol) - most honored out of the five contracts, powers all the complex Swyl membership logic. SwylClub is able to:
  - allows a potential club owner to create a `SwylClub` which then can be added with a number of SwylTier (i.e. membership plans). In each `SwylTier`, user can config their own desired amount of `Tier Fee`, arbitary amount of `Tier Limit` to limit the members in a `SwylTier`, update the metadata at any time
  - allows club owners to easily keep track of the total members and the total active members in each `SwylTier`, periodically make a request to `wipe off` inactive members,
  - allows a potential subscriber to subscribe/unsubscribe to any `SwylTier` in any `SwylClub` on the platform. `SwylClub` automatically calculates next payment in 30 days for the followers, records the very first date they started following the Club, increases the `SwylRoyaltyStars` (i.e. an Swyl honor system based on how long a follower follow a club)

# Get Started

## Requirement

- [git](https://git-scm.com/)
- [node.js](https://nodejs.org/en/)
- [yarn](https://yarnpkg.com/getting-started/install)
- [metamask](https://metamask.io/)

## Quickstart

```
git clone https://github.com/SWYLy/contracts.git
cd contracts
yarn
```

## Running the project

#### 1. Set environment variables

- create a `.env` file using the `.example.env` as the template and fill out the variables.

  - `SWYL_SERVICE_PRIVATE_KEY:` The private key of your [metamask](https://metamask.io/) account. See [Helpers.PRIVATE-KEY](https://github.com/swyly/contracts#1-how-to-export-private_key-from-your-metamask) on how to export your `PRIVATE KEY`. NOTE: FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT AND DO NOT SHARE YOUR PRIVATE KEY.
  - `MUMBAI_RPC_URL`: This is url of the `Mumbai` testnet node you're working with then deploy the `smart contracts` to. Setup with one for free from [Alchemy](https://www.alchemy.com/). See [Helpers.MUMBAI-RPC-URL](https://github.com/swyly/contracts#2-how-to-export-a-mumbai_rpc_url-from-alchemy) on how to export a `MUMBAI_RPC_URL` from [Alchemy](https://www.alchemy.com/).
  - `COINMARKETCAP_API_KEY`: This is mainly for the `hardhat-gas-report` pluggin so this is optional. If you want to play with `hardhat-gas-report` pluggin, first go to `hardhat.config.ts`, toggle the `gasReporter.enabled` to true. Then see [Helpers.COINMARKETCAP_API_KEY](https://github.com/swyly/contracts#3-how-to-export-a-coinmarketcap_api_key-from-coinmarketcap) on how to export your `COINMARKETCAP_API_KEY`

  #### 2. Get testnet `MUMBAI MATIC`

- Head to [Mumbai Faucet](https://mumbaifaucet.com/)
- Sign into the site using the [Alchemy](https://www.alchemy.com/) account you've created for the `MUMBAI_RPC_URL`
- Paste your [metamask](https://metamask.io/) `PUBLIC_KEY` a.k.a `account's address` (not `PRIVATE_KEY`)
- Hit `Send Me MATIC` to get free `MUMBAI MATIC`

#### 3. `Compile` smart contracts

###### 3.1 Using make command + hardhat

```
make compile
```

###### 3.2 Using yarn + hardhat

```
yarn hardhat compile
```

#### 4. `Deploy` smart contracts to `Mumbai Testnet`

###### 4.1 Using make command + hardhat

```
make deploy
```

###### 4.2 Using yarn + hardhat

```
yarn hardhat run ./deploy-scripts/v1/ --network mumbai
```

#### 5. `Verify` smart contracts on [etherscan](https://goerli.etherscan.io/)

###### 5.1 Using make command + hardhat

```
make verify
```

###### 5.2 Using yarn + hardhat

5.2.a. verify SwylClub Smart Contract

```
yarn hardhat verify --network mumbai ${SWYLCLUB_CONTRACT_ADDRESS_FROM_DEPLOY_PHASE} ${NATIVE_TOKEN_WRAPPER_ADDRESS}
```

5.2.b. verify SwylDonation Smart Contract

```
yarn hardhat verify --network mumbai ${SWYLDONATION_CONTRACT_ADDRESS_FROM_DEPLOY_PHASE} ${NATIVE_TOKEN_WRAPPER_ADDRESS}
```

5.2.a. verify Club Smart Contract

```
yarn hardhat verify --network mumbai ${SWYLERC721_CONTRACT_ADDRESS_FROM_DEPLOY_PHASE}
```

5.2.a. verify Club Smart Contract

```
yarn hardhat verify --network mumbai ${SWYLERC1155_CONTRACT_ADDRESS_FROM_DEPLOY_PHASE}
```

5.2.a. verify Club Smart Contract

```
yarn hardhat verify --network mumbai ${SWYLMARKETPLACE_CONTRACT_ADDRESS_FROM_DEPLOY_PHASE} ${NATIVE_TOKEN_WRAPPER_ADDRESS} ${PLATFORM_FEE_SERVICE_RECIPIENT} ${PLATFORM_FEE_BPS(%)}
```

# Helpers

### 1. How to export `PRIVATE_KEY` from your [metamask](https://metamask.io/)

[How to export an account's private key](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key)

### 2. How to export a `MUMBAI_RPC_URL` from [Alchemy](https://www.alchemy.com/).

- Go to [Alchemy](https://www.alchemy.com/) => `Signup` => `Signin`
- Hit `CREATE APP` => fill out the form
  ```
    {
      NAME: 'ANY',
      DESCRIPTION: 'ANY',
      CHAIN: 'Polygon',
      NETWORK: 'Mumbai`
    }
  ```
- Now, go to the app you just created. Find and click on the `VIEW KEY` button top-right.
- The `URL` under `HTTPS` is the `MUMBAI_RPC_URL` you want.
- Copy the `URL` and paste it to your `.env` file under `MUMBAI_RPC_URL`

### 3. How to export a `COINMARKETCAP_API_KEY` from [coinmarketcap](https://coinmarketcap.com/)

- Go [here](https://coinmarketcap.com/api/pricing/) and pick the first plan-`GET FREE API KEY`.
- Signup with your email then sign into [coinmarketcap](https://pro.coinmarketcap.com/account)
- Now copy the API Key there and paste it to your `.env` file under `COINMARKETCAP_API_KEY`

# Verified on [Etherscan](https://goerli.etherscan.io/)
