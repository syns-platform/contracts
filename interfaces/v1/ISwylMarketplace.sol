/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Honor: Thirdweb/contracts
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/** EXTERNAL IMPORT */
import "@thirdweb-dev/contracts/interfaces/IThirdwebContract.sol";
import "@thirdweb-dev/contracts/extension/interface/IPlatformFee.sol";

/**
 *  The `ISwylMarketplace` interface implements the Thirdweb/IMarketplace.
 */
interface ISwylMarketplace is IThirdwebContract, IPlatformFee {
    /// @notice Type of the tokens that can be listed for sale.
    enum TokenType {
        ERC1155,
        ERC721
    }

    /**
     *  @notice `Direct`: NFTs listed for sale at a fixed price.
     */
    enum ListingType {
        Direct
    }

    /**
     *  @notice The information related to an offer on a direct listing
     *
     *  @param listingId            uint256 - The uid of the listing the offer is made to.
     *  @param offeror              address - The account making the offer.
     *  @param quantityWanted       uint256 - The quantity of tokens from the listing wanted by the offeror.
     *  @param currency             address - The currency in which the offer is made.
     *  @param pricePerToken        uint256 - The price per token offered to the lister.
     *  @param expirationTimestamp  uint256 - The timestamp after which a seller cannot accept this offer.
     */
    struct OfferParameters {
        uint256 listingId;
        address offeror;
        uint256 quantityWanted;
        address currency;
        uint256 pricePerToken;
        uint256 expirationTimestamp;
    }

    /**
     *  @dev For use in `createListing()` as a parameter type.
     *
     *  @param assetContract                address - The NFT contract address of the token to list for sale.
     *
     *  @param tokenId                      uint256 - The tokenId on `assetContract` of the NFT to list for sale.
     *
     *  @param startSale                    uint256 - The unix timestamp after which the listing is active.'Active' means NFTs can be bought from the listing.
     *
     *  @param listingDuration              uint256 - No. of seconds after which the listing is inactive, i.e. NFTs cannot be bought
     *                                                  or offered. Creator can set this to a time or date they want, or pick `unlimited`
     *                                                  to make the listing `active` until it gets bought or canceled.
     *
     *  @param quantityToList               uint256 - The quantity of NFT of ID `tokenId` on the given `assetContract` to list. For
     *                                                  ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                                                  Regardless of the value of `quantityToList` passed.
     *
     *  @param currencyToAccept             address - The currency in which a buyer must pay the listing's fixed price to buy the NFT(s).
     *
     *  @param buyoutPricePerToken          uint256 - Price per token listed.
    **/
    struct DirectListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 startSale;
        uint256 listingDuration;
        uint256 quantityToList;
        address currencyToAccept;
        uint256 buyoutPricePerToken;
    }

    /**
     *  @notice The information related to a direct listing -- Market Items;
     *
     *  @param listingId             uint256 - The uid for the listing.
     *
     *  @param tokenOwner            address - The owner of the tokens listed for sale a.k.a Seller.
     *
     *  @param assetContract         address - The contract address of the NFT to list for sale.
     *
     *  @param tokenId               uint256 - The tokenId on `assetContract` of the NFT to list for sale.
     *
     *  @param startSale             uint256 - The unix timestamp after which the listing is active. 'Active' means NFTs can be bought from the listing.
     *
     *  @param endSale               uint256 - No. of seconds after `startSale` which the listing is inactive, i.e. NFTs cannot be bought
     *                                          or offered. Creator can set this to a time or date they want, or pick `unlimited`
     *                                          to make the listing `active` until it gets bought or canceled.
     *
     *  @param quantity              uint256 - The quantity of NFT of ID `tokenId` on the given `assetContract` listed. For
     *                                          ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                                          Regardless of the value of `quantityToList` passed.
     *
     *  @param currency              address - The currency in which a buyer must pay the listing's fixed price to buy the NFT(s). 
     *
     *  @param buyoutPricePerToken   uint256 - Price per token listed.
     *
     *  @param tokenType             TokenType - The type of the token(s) listed for for sale -- ERC721 or ERC1155 
    **/
    struct Listing {
        uint256 listingId;
        address tokenOwner;
        address assetContract;
        uint256 tokenId;
        uint256 startSale;
        uint256 endSale;
        uint256 quantity;
        address currency;
        uint256 buyoutPricePerToken;
        TokenType tokenType;
    }

    /// @dev Emitted when a new listing is created.
    event ListingAdded(uint256 indexed listingId, address indexed assetContract, address indexed lister, Listing listing);

    /// @dev Emitted when the parameters of a listing are updated.
    event ListingUpdated(uint256 indexed listingId, address indexed listingCreator);

    /// @dev Emitted when a listing is cancelled.
    event ListingRemoved(uint256 indexed listingId, address indexed listingCreator);

    /**
     * @dev Emitted when a buyer buys from a direct listing, or a lister accepts some
     *      buyer's offer to their direct listing.
     */
    event NewSale(
        uint256 indexed listingId,
        address indexed assetContract,
        address indexed lister,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /// @dev Emitted when (1) a new offer is made to a direct listing, or (2) when a new bid is made in an auction.
    event NewOffer(
        uint256 indexed listingId,
        address indexed offeror,
        ListingType indexed listingType,
        uint256 quantityWanted,
        uint256 totalOfferAmount,
        address currency
    );

    /**
     *  @notice Lets a token owner list tokens (ERC 721 or ERC 1155) for sale in a direct listing.
     *
     *  @dev The NFT `assetContract` only passes the checks whether the listing's creator owns and 
     *       has approved Marketplace to transfer the NFTs to list.
     *
     *  @param _params The parameters that govern the listing to be created. See DirectListingParameters for more info on how _params should be formed
     */
    function createListing(DirectListingParameters memory _params) external;



    /**
     *  @notice Lets a listing's creator edit the listing's parameters. Direct listings can be edited whenever.
     *
     *  @param _listingId            uint256 - The uid of the lisitng to edit.
     *
     *  @param _quantityToList       uint256 - The amount of NFTs to list for sale in the listing. The NFT `assetContract` only
     *                                          passes checks whether the listing's creator owns and has approved Marketplace to transfer
     *                                          `_quantityToList` amount of NFTs to list for sale.
     *
     *  @param _buyoutPricePerToken  uint256 - Price per token listed.
     *
     *  @param _currencyToAccept     address - For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                                          to buy the NFT(s). For auctions: the currency in which the bidders must make bids.
     *
     *  @param _startSale            The unix timestamp after which listing is active. 'Active' means NFTs can be bought from the listing.
     *
     *  @param _listingDuration      uint256 - No. of seconds after which the listing is inactive, i.e. NFTs cannot be bought
     *                                          or offered. Creator can set this to a time or date they want, or pick `unlimited`
     *                                          to make the listing `active` until it gets bought or canceled.
     */
    function updateListing(
        uint256 _listingId,
        uint256 _quantityToList,
        uint256 _buyoutPricePerToken,
        address _currencyToAccept,
        uint256 _startSale,
        uint256 _listingDuration
    ) external;


    /**
     *  @notice Lets a direct listing creator cancel their listing.
     *
     *  @param _listingId The uid of the lisitng to cancel.
     */
    function cancelDirectListing(uint256 _listingId) external;


    /**
     *  @notice Lets someone buy a given quantity of tokens from a direct listing by paying the price.
     *
     *  @param _listingId       uint256 - The uid of the direct lisitng to buy from.
     *  @param _buyer           address - The receiver of the NFT being bought.
     *  @param _quantity        uint256 - The amount of NFTs to buy from the direct listing.
     *  @param _currency        address - The currency to pay the price in.
     *  @param _totalPrice      uint256 - The total price to pay for the tokens being bought.
     *
     *  @dev A sale will fail to execute if either:
     *          (1) buyer does not own or has not approved Marketplace to transfer the appropriate
     *              amount of currency (or hasn't sent the appropriate amount of native tokens)
     *
     *          (2) the lister does not own or has removed Markeplace's
     *              approval to transfer the tokens listed for sale.
     */
    function buy(
        uint256 _listingId,
        address _buyer,
        uint256 _quantity,
        address _currency,
        uint256 _totalPrice
    ) external payable;
    

    /**
     *  @notice Lets someone make an offer to an existing direct listing.
     *
     *  @dev Each (address, listing ID) pair maps to a single unique offer. E.g. if a buyer makes
     *       two offers to the same direct listing, the last offer is counted as the buyer's
     *       offer to that listing.
     *
     *  @param _listingId           uint256 = The unique ID of the lisitng to make an offer to.
     *
     *  @param _quantityWanted      uint256 = The quantity of NFTs from the listing, for which the offer is being made.
     *
     *  @param _currency            address - The currency in which the offer is made.
     *
     *  @param _pricePerToken       uint256 = For direct listings: offered price per token.
     *
     *  @param _offerDuration       uint256 = No. of seconds after which the offer is inactiv and the seller can no longer accept the offer.
     */
    function offer(
        uint256 _listingId,
        uint256 _quantityWanted,
        address _currency,
        uint256 _pricePerToken,
        uint256 _offerDuration
    ) external payable;
    

    /**
     * @notice Lets a listing's creator accept an offer to their direct listing.
     *
     * @param _listingId            uint256 - The unique ID of the listing for which to accept the offer.
     *
     * @param _offeror              address - The address of the buyer whose offer is to be accepted.
     *
     * @param _currency             address - The currency of the offer that is to be accepted.
     *
     * @param _totalPrice           uint256 - The total price of the offer that is to be accepted.
     */
    function acceptOffer(
        uint256 _listingId,
        address _offeror,
        address _currency,
        uint256 _totalPrice
    ) external;

}
