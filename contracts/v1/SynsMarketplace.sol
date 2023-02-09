/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Honor: Thirdweb & Openzeppeline
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import "@thirdweb-dev/contracts/lib/FeeType.sol";

//  ==========  Internal imports    ==========
import { ISynsMarketplace } from "../../interfaces/v1/ISynsMarketplace.sol";


contract SynsMarketplace is 
    Initializable,
    ISynsMarketplace,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{ 
    
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice module level info
    bytes32 private constant MODULE_TYPE = bytes32("Syns-Marketplace");
    uint256 private constant VERSION = 1;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The max bps of the contract. 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

     /// @dev The address that receives all platform fees from all sales.
    address private synsServiceFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint64 private synsServiceFeeBps;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 public constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The address of the native token wrapper contract i.e. 0xeee.
    address private immutable nativeTokenWrapper;

    /// @dev Total number of listings ever created in the marketplace.
    uint256 public totalListings;


    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/
    
    /// @dev Mapping from uid of listing => listing info. All the listings on the marketplace
    mapping(uint256 => Listing) private totalListingItems;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    /// @notice v2.0 features
    mapping(uint256 => mapping(address => OfferParameters)) private offers;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether the caller is the listing's creator.
    modifier onlyListingOwner(uint256 _listingId) {
        require(totalListingItems[_listingId].tokenOwner == _msgSender(), "!OWNER");
        _; // move on
    }

    /// @dev Checks whether a listing exists
    modifier onlyExistingListing(uint256 _listingId) {
        // Make sure the NFT assetContract is a valid address
        require(totalListingItems[_listingId].assetContract != address(0), "DNE");
        _; //move on
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /** 
    * @dev This contract utilizes the @openzeppelin/upgradeable pluggin and then will be deployed behind a proxy.
    *       A proxied contract doesn't make use of a constructor and the logic in a constructor got moved into 
    *       an external initializer function.
    *
    * NOTE from EIP7221: Secure Protocol for Native Meta Transactions (https://eips.ethereum.org/EIPS/eip-2771)
    *           - Transaction Signer - entity that signs & sends to request to Gas Relay
    *           - Gas Relay - receives a signed request off-chain from Transaction Signer and pays gas to turn it into a valid transaction that goes through Trusted Forwarder
    *           - Trusted Forwarder - a contract that is trusted by the Recipient to correctly verify the signature and nonce before forwarding the request from Transaction Signer
    *           - Recipient - a contract that can securely accept meta-transactions through a Trusted Forwarder by being compliant with this standard.
    *
    * @notice deploying to a proxy, constructor won't be in use.
    */ 
    constructor(
        address _nativeTokenWrapper, 
        address _platformFeeRecipient, // synsServiceFeeRecipient
        uint256 _platformFeeBps //synsServiceFeeBps
    ) initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls

        // set nativeTokenWrapper
        nativeTokenWrapper = _nativeTokenWrapper;

        // set platform admin/contract's state info
        synsServiceFeeRecipient = _platformFeeRecipient;
        synsServiceFeeBps = uint64(_platformFeeBps);

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Syns Service account
        _setupRole(LISTER_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0)); 
    }

    /**
    * @dev This function acts like a constructor on deploying to proxy.
    *       initializer modifier is marked to make sure this function can ever be called once in this contract's lifetime
    * NOTE  from EIP7221: Secure Protocol for Native Meta Transactions (https://eips.ethereum.org/EIPS/eip-2771)
    *           - Transaction Signer - entity that signs & sends to request to Gas Relay
    *           - Gas Relay - receives a signed request off-chain from Transaction Signer and pays gas to turn it into a valid transaction that goes through Trusted Forwarder
    *           - Trusted Forwarder - a contract that is trusted by the Recipient to correctly verify the signature and nonce before forwarding the request from Transaction Signer
    *           - Recipient - a contract that can securely accept meta-transactions through a Trusted Forwarder by being compliant with this standard.
    */
    function initialize(
        address _defaultAdmin, // original deployer i.e. Syns Service account
        string memory _contrtactURI, // contract level URI
        address[] memory _trustedForwarders,
        address _platformFeeRecipient, // synsServiceFeeRecipient
        uint256 _platformFeeBps //synsServiceFeeBps
    ) external initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls
        __ERC2771Context_init(_trustedForwarders); // init trusted forwarders

        // set platform admin/contract's state info
        contractURI = _contrtactURI;
        synsServiceFeeRecipient = _platformFeeRecipient;
        synsServiceFeeBps = uint64(_platformFeeBps);

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Syns Service account in this case
        _setupRole(LISTER_ROLE, address(0)); // grant LISTER_ROLE to address 0x000
        _setupRole(ASSET_ROLE, address(0)); // grant ASSET_ROLE to address 0x000
    }


    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/
    
    /**
    * @notice receive() is a special function and only one can be defined in a smart contract.
    *       It executes on calls to the contract with no data(calldata), e.g. calls made via send() or transfer()
    *
    * @dev Lets the contract receives native tokens from `nativeTokenWrapper` withdraw
    */ 
    receive() external payable {}

    /// @dev Returns the module type of the contract
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }


    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 1155 logic
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Handles the receipt of a single ERC1155 token type. This function is
    * called at the end of a `safeTransferFrom` after the balance has been updated.
    *
    * NOTE: To accept the transfer, this must return
    * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * (i.e. 0xf23a6e61, or its own function selector).
    *
    * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address, // operator    - The address which initiated the transfer, i.e. SynsMarketplace in this case
        address, // from        - The address which previously owned the token
        uint256, // id          - The ID of the token being transferred
        uint256, // value       - The amount of tokens being transferred
        bytes memory //data     - Additional data with no specified format
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }


    /**
    * @dev Handles the receipt of a multiple ERC1155 token types. This function
    * is called at the end of a `safeBatchTransferFrom` after the balances have
    * been updated.
    *
    * NOTE: To accept the transfer(s), this must return
    * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * (i.e. 0xbc197c81, or its own function selector).
    * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address, // operator            - The address which initiated the batch transfer (i.e. msg.sender), i.e. SynsMarketplace in this case
        address, // from                - The address which previously owned the token
        uint256[] memory, // ids        - An array containing ids of each token being transferred (order and length must match values array)
        uint256[] memory, // values     - An array containing amounts of each token being transferred (order and length must match ids array)
        bytes memory // data            - Additional data with no specified format
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    
    /**
    * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
    * by `operator` from `from`, this function is called.
    *
    * It must return its Solidity selector to confirm the token transfer.
    * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
    *
    * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
    */
    function onERC721Received(
        address, // operator        - The address which initiated the batch transfer (i.e. msg.sender), i.e. SynsMarketplace in this case
        address, // from            - The address which previously owned the token
        uint256, // tokenId         - The ID of the token being transferred
        bytes calldata // data      - Additional data with no specified format
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    /**
    * @dev Returns true if this contract implements the interface defined by
    * `interfaceId`. See the corresponding
    * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    * to learn more about how these ids are created.
    *
    * This function call must use less than 30 000 gas.
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /*///////////////////////////////////////////////////////////////
                Listing (create-update-cancel) logic
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Lets a token owner create an item to list on the marketplace (listing).
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    */ 
    function createListing(DirectListingParameters memory _param) external override {

        // Get tokenOwner
        address tokenOwner = _msgSender();
        
        // Get the array of listings owned by owner
        Listing[] memory listingsOwnedByTokenOwner = getListingsOwnedBy(tokenOwner);

        // Check roles
        require(hasRole(LISTER_ROLE, address(0)) || hasRole(LISTER_ROLE, tokenOwner), "INVALID ROLE - account must have LISTER_ROLE role");
        require(hasRole(ASSET_ROLE, address(0)) || hasRole(ASSET_ROLE, _param.assetContract), "INVALID ROLE - account must have ASSET_ROLE role");
        
        // Get token info
        TokenType listTokenType = getTokenType(_param.assetContract);


        // Check if tokenAmountToList is valid
        uint256 tokenAmountToList = getSafeQuantity(listTokenType, _param.quantityToList);
        require(tokenAmountToList > 0, "INVALID QUANTITY - must be greater than 0");

        // Check if the `tokenOwner` has enough token quantity to list.
        bool sufficientQuantity = validateQuantityToList(tokenOwner, _param.assetContract, _param.tokenId, tokenAmountToList, listTokenType);
        require(sufficientQuantity, "INVALID QUANTITY - insufficient quantity");


        // validate token's ownership and approval
        validateOwnershipAndApproval(tokenOwner, _param.assetContract, _param.tokenId, tokenAmountToList, listTokenType);


        // check if an NFT has already been listed on Syns's platform -- only applicable for ERC1155 NFTs
        (
            bool isListed, 
            uint256 existingListingId
        ) = checkTokenAlreadyListed(
                listingsOwnedByTokenOwner, 
                _param.assetContract, 
                _param.tokenId,
                _param.currencyToAccept,
                _param.buyoutPricePerToken
            );


        /**
        * @NOTE if `isListed` == true => the ERC1155-token-type-NFT is already listed,
        *       then this listing should be appended to the listing that has already been created.
        *       
        *       if `isListed` == false => the token could be a new ERC721 NFT or ERC1155 NFT that has never been listed before,
        *       then this listing should be pushed to the global `totalListingItems[]` with a new index.
        */
        if (isListed) {
            Listing memory existingListing = totalListingItems[existingListingId];
            
            // append more `_quantityToList` amount of token to existedToken
            existingListing.quantity += tokenAmountToList;

            // update global array
            totalListingItems[existingListingId] = existingListing;

            // emit ListingAppend event
            emit ListingAppend(totalListings, existingListing.assetContract, tokenOwner, existingListing);
        } else {
            // Get next listingId to list
            uint256 listingId = totalListings;
            totalListings += 1;

            // create new listing
            Listing memory newListing = Listing({
                listingId: listingId,
                tokenOwner: tokenOwner,
                assetContract: _param.assetContract,
                tokenId: _param.tokenId,
                startSale: block.timestamp, // set to current time - could be dynamic in future
                endSale: type(uint256).max, // set to infinity - could be dynamic in future
                quantity: tokenAmountToList,
                currency: _param.currencyToAccept,
                buyoutPricePerToken: _param.buyoutPricePerToken,
                tokenType: listTokenType
            });

            // adds listing to mapping totalListingItems
            totalListingItems[listingId] = newListing;

            // emit ListingAdded event
            emit ListingAdded(listingId, newListing.assetContract, tokenOwner, newListing);
        }

    }


    /**
    * @dev Lets a listing creator update the listing's metadata. More info can be found in interfaces/v1/ISynsMarketplace.sol
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    */
    function updateListing(
        uint256 _listingId, 
        uint256 _quantityToList, 
        uint256 _buyoutPricePerToken, 
        address _currencyToAccept
    ) external override onlyListingOwner(_listingId){
        // get targetListing
        Listing memory targetListing = totalListingItems[_listingId];

        // assure the new _quantityToList is a safe quantity (i.e. equals 1 if ERC721 is supported)
        uint256 safeNewQuantity = getSafeQuantity(targetListing.tokenType, _quantityToList);
        require(safeNewQuantity != 0, "QUANTITY - must be greater than 0");

        /** @notice Checking quantity. Only for ERC1155 token, 
        *               (1) if the desired `safeNewQuantity` is greater than `targetListing.quantity`,
        *               a check needs to be execute to make sure the `extraQuantity` is in the valid area.
        *
        *               (2) if the desired `safeNewQuantity` is less than `targetListing.quantity`,
        *               the desired `safeNewQuantity` is AUTOMATICALLy in the safe zone (i.e. no check needed).
        */
        if (targetListing.tokenType == TokenType.ERC1155 && targetListing.quantity < safeNewQuantity) {
            // calculate the extra quantity
            uint256 extraQuantity = safeNewQuantity - targetListing.quantity;

            // check if the `tokenOwner` has enough token quantity to list.
            bool sufficientQuantity = validateQuantityToList(_msgSender(), targetListing.assetContract, targetListing.tokenId, extraQuantity, targetListing.tokenType);
            require(sufficientQuantity, "INVALID QUANTITY - insufficient extra quantity");
        }

        // if safeNewQuantity != targetListing.quantity => must re-validate and re-approval of the new quantity of tokens for direct listing 
        if (safeNewQuantity != targetListing.quantity) {
            validateOwnershipAndApproval(
                targetListing.tokenOwner, 
                targetListing.assetContract, 
                targetListing.tokenId, 
                safeNewQuantity, 
                targetListing.tokenType
            );
        }


        // update targetListing
        targetListing.quantity = safeNewQuantity;
        targetListing.buyoutPricePerToken = _buyoutPricePerToken;
        targetListing.currency = _currencyToAccept;

        // update global totalListingItems
        totalListingItems[_listingId] = targetListing;

        // finally, emit the ListingUpdated event
        emit ListingUpdated(targetListing.listingId, targetListing.tokenOwner);
    }


    /**
    * @dev Lets a listing creator cancel a listing.
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    */
    function cancelListing(uint256 _listingId) external override onlyListingOwner(_listingId){
        // delete from totalListingItems
        delete totalListingItems[_listingId];

        // emit event
        emit ListingRemoved(_listingId, _msgSender());
    }


    /*///////////////////////////////////////////////////////////////
                    Direct lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Lets someone buy a given quantity of tokens from a direct listing by paying the price 
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    */
    function buy(
        uint256 _listingId, 
        address _receiver, 
        uint256 _quantity, 
        address _currency, 
        uint256 _totalPrice
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        // get targetListing
        Listing memory targetListing = totalListingItems[_listingId];

        // Check if tokenAmountToList is valid
        uint256 tokenAmountToList = getSafeQuantity(targetListing.tokenType, _quantity);
        require(tokenAmountToList > 0, "INVALID QUANTITY - must be greater than 0");

        // get totalPriceToPay = price per token * desired `_quantity`
        uint256 totalPriceToPay = targetListing.buyoutPricePerToken * tokenAmountToList;

        // get buyer address
        address buyer = _msgSender();

        // check where the settled total price and currency to use are correct
        require(
            _currency == targetListing.currency && _totalPrice == totalPriceToPay,
            "!PRICE - invalid totalprice"
        );

        executeSale(
            targetListing,
            buyer,
            _receiver,
            targetListing.currency,
            totalPriceToPay,
            tokenAmountToList
        );
    }


    /**
     *  @notice Executes a sale
     *
     *  @param _targetListing               Listing - the target listing which is to be executed
     *  @param _buyer                       address - The buyer who pays for the execution
     *  @param _receiver                    address - The receiver of the NFT being bought.
     *  @param _currency                    address - The currency to pay the price in.
     *  @param _totalPriceToTransfer        uint256 - The amount of NFTs to buy from the direct listing.
     *  @param _quantityToTransfer          uint256 - The total price to pay for the tokens being bought.
     *
     */
    function executeSale(
        Listing memory _targetListing,
        address _buyer,
        address _receiver,
        address _currency,
        uint256 _totalPriceToTransfer,
        uint256 _quantityToTransfer
    ) internal {

        /// @dev validate dirrect listing sale
        ///       (1) Check if quantity is valid
        ///       (2) Check if the `_buyer` has enough fund in their bank account
        validateDirectListingSale(
            _targetListing,
            _buyer,
            _quantityToTransfer,
            _currency,
            _totalPriceToTransfer
        );

        /// @dev transfer currency
        ///     (1) to SynsServiceFeeRecipient
        ///     (2) to original creator (royaltyRecipient)
        ///     (3) to token owner
        payout(
            _buyer, 
            _targetListing.tokenOwner, 
            _currency, 
            _totalPriceToTransfer, 
            _targetListing
        );

        // transfer tokens
        transferListingTokens(
            _targetListing.tokenOwner,
            _receiver,
            _quantityToTransfer,
            _targetListing
        );

        emit NewSale(
            _targetListing.listingId, 
            _targetListing.assetContract, 
            _targetListing.tokenOwner, 
            _receiver, 
            _quantityToTransfer, 
            _totalPriceToTransfer);

    }


    /**
    * @notice v2.0 features
    * @dev Lets someone make an offer to an existing direct listing
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    * NOTE Coming in SynsMarketplace v2
    */
    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        address _currency, 
        uint256 _pricePerToken, 
        uint256 _offerDuration
    ) external payable nonReentrant onlyExistingListing(_listingId) {}

    /**
    * @notice v2.0 features
    * @dev Lets a listing's creator accept an offer to their direct listing
    *
    * NOTE More info can be found in interfaces/v1/ISynsMarketplace.sol
    * NOTE Coming in SynsMarketplace v2
    */
    function acceptOffer(
        uint256 _listingId, 
        address _offeror, 
        address _currency, 
        uint256 _totalPrice
    ) external override onlyListingOwner(_listingId) onlyExistingListing(_listingId) {}



    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
    * @notice checks if a token with assetAddress & tokenId & tokenOwner has already been listed for sale
    * 
    * @dev loops through the array of listing owned by token owner to find out if the token with `_assetContract`, `_tokenId` is already listed
    *
    * @param _assetContract                     address - the address of the token being validated
    *
    * @param tokenOwner                         address - the owner address of the token 
    *
    * @param _tokenId                           uint256 - the token Id of the token being validated
    *
    * @return _isListed                         bool - true if the token already exists and vice versa
    */
    function checkTokenListed(address _assetContract, address tokenOwner, uint256 _tokenId) public view returns (bool _isListed, uint256 listingId) {
        Listing[] memory listingsOwnedByTokenOwner = getListingsOwnedBy(tokenOwner);

        for (uint256 i = 0; i < listingsOwnedByTokenOwner.length; i++) {
            // Finding target existing listing
            if (listingsOwnedByTokenOwner[i].assetContract == _assetContract &&
                listingsOwnedByTokenOwner[i].tokenId == _tokenId 
            ) {
                return (true, listingsOwnedByTokenOwner[i].listingId);
            }
        }
        return (false, type(uint256).max);
    }


     /**
    *  @dev loops through the array of listings owned by _msg.Sender() to find out if the token 
    *       with `_assetContract`, `_tokenId`, `_currencyToAccept`, and `_listingPrice` is already listed.
    *
    *  @param listings                          Listing[] - The array of listings owned by _msg.Sender()
    *
    *  @param _assetContract                    address - the address of the token being validated
    *
    *  @param _tokenId                          uint256 - the token Id of the token being validated
    *
    *  @return _isListed                        bool - true if the token already exists and vice versa
    *
    *  @return _existingListingId               uint256 - the listingId of the existed listing inside global `totalListingItems` array
    */
    function checkTokenAlreadyListed(
        Listing[] memory listings,
        address _assetContract,
        uint256 _tokenId,
        address _currencyToAccept,
        uint256 _listingPrice
    ) public pure returns (
        bool _isListed, 
        uint256 _existingListingId
    ) {
        for (uint256 i = 0; i < listings.length; i++) {
            // Finding target existing listing
            if (listings[i].assetContract == _assetContract &&
                listings[i].tokenId == _tokenId &&
                listings[i].currency == _currencyToAccept &&
                listings[i].buyoutPricePerToken == _listingPrice
            ) {
                return (true, listings[i].listingId);
            }
        }
        return (false, 0);
    }

    /**
    *  @dev validate the desired `_quantity` is valid with the logic:
    *           (1) ERC721 NFTs: should be listed only once
    *           (2) ERC1155 NFTs: can be listed multiple times as long as the desired `_quantity` should be in the range from 0 to the total balance owned by `_tokenOwner`
    *
    *  @param _tokenOwner           address - the owner of the token being validated
    *
    *  @param _assetContract        address - the address of the token being validated
    *
    *  @param _tokenId              uint256 - the token Id of the token being validated
    *
    *  @param _quantity             uint256 - the quantity of the token being validated
    *
    *  @param _tokenType            TokenType - ERC721 or ERC1155
    */
    function validateQuantityToList (
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view returns (bool)
    {
        // get the array of Listings owned by `_tokenOwner`
        Listing[] memory listings = getListingsOwnedBy(_tokenOwner);

        if (_tokenType == TokenType.ERC721) {
            // looping through listings
            for (uint i = 0; i < listings.length; i++) {

                /**
                * @dev if _assetContract and _tokenId is found in the list of `listings` => the listing has been created => FAILING CONDITION
                */
                if (listings[i].assetContract == _assetContract && listings[i].tokenId == _tokenId) {
                    return false;
                }
            }
        } else if (_tokenType == TokenType.ERC1155) {
            // get ERC1155's total balance owned by the `_tokenOwner`
            uint256 totalBalanceOwnedByOwner = IERC1155Upgradeable(_assetContract).balanceOf(_tokenOwner, _tokenId);

            // get ERC1155's balance the `_tokenOwner` has left
            uint256 balanceLeftToList = getBalanceLeftToList(listings, _assetContract, _tokenId, totalBalanceOwnedByOwner);

            /**
            * @notice if `balanceLeftToList` == `totalBalanceOwnedByOwner` => the token has never been listed before => PASSING CONDITION
            *         if `balanceLeftToList` < `totalBalanceOwnedByOwner` => the token has been listed before but not 100% balance => PASSING CONDITION
            *         if `balanceLeftToList` >= `_quantity` => the desired `_quantity` is in the valid area => PASSING CONDITION
            *         if `balanceLeftToList` < `_quantity` => the desired `_quantity` is in the invalid area => FAILING CONDITION
            *         if `balanceLeftToList` == 0 => the token has been listed before with 100% balance => FAILING CONDITION
            */
            if (balanceLeftToList < _quantity || balanceLeftToList == 0) {
                return false;
            }
        }

        // return true if all conditions pass
        return true;
    }



    /**
    *  @dev validate that `_tokenOwner` owns and has approved SynsMarketplace to transfer NFTs
    *
    *  @param _tokenOwner           address - the owner of the token being validated
    *
    *  @param _assetContract        address - the address of the token being validated
    *
    *  @param _tokenId              uint256 - the token Id of the token being validated
    *
    *  @param _quantity             uint256 - the quantity of the token being validated
    *
    *  @param _tokenType            TokenType - ERC721 or ERC1155
    */
    function validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view 
    {
        // get SynsMarketplace's address
        address SynsMarketplaceAddress = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid = 
                IERC1155Upgradeable(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity && // check if owner has enough balance to list
                IERC1155Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, SynsMarketplaceAddress); // check if owner approved SynsMarketplaceAddress to list their NFTs
        } else if (_tokenType == TokenType.ERC721) {
            isValid = 
                IERC721Upgradeable(_assetContract).ownerOf(_tokenId) == _tokenOwner && // check if the _tokenOwner owns the token
                (IERC721Upgradeable(_assetContract).getApproved(_tokenId) == SynsMarketplaceAddress || // check if SynsMarkplace is appeared in token's approve list
                IERC721Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, SynsMarketplaceAddress)); // check if _tokenOwner approves SynsMarketplace
        }
        require(isValid, "!INVALID OWNERSHIP AND APPROVAL");
    }


    /**
    *  @dev validate dirrect listing sale
    *           (1) Check if quantity is valid
    *           (2) Check if the `_buyer` has enough fund in their bank account
    *
    *  @param _listing              Listing - the target listing being validated
    *
    *  @param _buyer                address - the address who is paying for the sale
    *
    *  @param _quantityToBuy        uint256 - the desired quantity to buy
    *
    *  @param _currency             address - the address of the currency to buy
    *
    *  @param settledTotalPrice     uint256 - the total price to buy
    */
    function validateDirectListingSale(
        Listing memory _listing,
        address _buyer,
        uint256 _quantityToBuy,
        address _currency,
        uint256 settledTotalPrice
    ) internal {
        // Check whether a valid quantity of listed tokens is being bought
        require(
            _listing.quantity > 0 && _quantityToBuy > 0 && _quantityToBuy <= _listing.quantity,
            "!QUANTITY - invalid quantity of tokens"
        );

        // Check buyer owns and has approved sufficient currency for sale
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) { // if currency is native token of a chain
            require(msg.value == settledTotalPrice, "!FUND - msg.value != total price");
        } else { // if currency is custom ERC20 token
            validateERC20BalAndAllowance(_buyer, _currency, settledTotalPrice);
        }

        // Check whether token owner owns and has approved `quantityToBuy` amount of listing tokens form the listing
        validateOwnershipAndApproval(
            _listing.tokenOwner, 
            _listing.assetContract, 
            _listing.tokenId, 
            _quantityToBuy, 
            _listing.tokenType);
    }


    /**
    *  @dev validate ERC20 tokens
    *
    *  @param _addressToCheck                       address - the address to check against with
    *
    *  @param _currency                             address - the address of the currency to check
    *
    *  @param _currencyAmountToCheckAgainst         uint256 - the total currency amount to check
    *
    *  NOTE Openzepplin/IERC20Upgradeable - allowance api returns the remaining number of tokens 
    *                                       that spender (i.e. SynsMarketplace address) will be allowed to spend 
    *                                       on behalf of owner (i.e. _buyer) through transferFrom. This is zero by default.
    */
    function validateERC20BalAndAllowance(
        address _addressToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20Upgradeable(_currency).balanceOf(_addressToCheck) >= _currencyAmountToCheckAgainst &&
            IERC20Upgradeable(_currency).allowance(_addressToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "!BALANCE20 - insufficient balance"
        );
    }

    /**
    *  @dev Pays out the the transactions
    *
    *  @param _payer                        address - the address that pays the price amount
    *
    *  @param _payee                        address - the address that receives the price amount
    *
    *  @param _currencyToUse                address - the address of the currency passed in
    *
    *  @param _totalPayoutAmount            uint256 - the total currency amount to pay
    *
    *  @param _listing                      Listing - the target listing to be bought
    */
    function payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) internal {
        // calculate platformFeeCut
        uint256 platformFeeCut = (_totalPayoutAmount * synsServiceFeeBps) / MAX_BPS;

        // royalty info
        uint256 royaltyCut;
        address royaltyRecipient;

        // Distribute royalties. 
        // See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        /*
        * NOTE: IERC2981 -  Interface for the NFT Royalty Standard.
        * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
        * support for royalty payments across all NFT marketplaces and ecosystem participants.
        * 
        * Resource: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC2981.sol
        */
        /**
        * @dev IERC2981Upgradeable(_).royaltyInfo(_,_) returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
        * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
        */
        try IERC2981Upgradeable(_listing.assetContract).royaltyInfo(_listing.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount, "fees exceed the price");
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Get nativeTokenWrapper address
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Distribute price to SynsServiceFeeRecipient account
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse, 
            _payer, 
            synsServiceFeeRecipient, 
            platformFeeCut,
            _nativeTokenWrapper
        );

        // Distribute price to original author receipient
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse, 
            _payer, 
            royaltyRecipient, 
            royaltyCut, 
            _nativeTokenWrapper
        );

        // Distribute price to receiver (i.e. token's owner)
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse, 
            _payer, 
            _payee, 
            _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );

        emit ListingPaidOutInformation(royaltyRecipient, royaltyCut, platformFeeCut);
    }

    /**
    *  @dev Transfers tokens listed for sale in a direct or auction listing.
    *
    *  @param _from                         address - the address of the token's owner
    *
    *  @param _to                           address - the address of the buyer
    *
    *  @param _quantity                     uint256 - the total quantity of the token being transfered
    *
    *  @param _listing                      Listing - the target listing to be bought
    */
    function transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            // Transfer the token to the `_to` address
            IERC1155Upgradeable(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, _quantity, "");

            // Update global `totalListingItems`
            if (_listing.quantity == _quantity) {
                delete totalListingItems[_listing.listingId];
            } else {
                // update _targetListing.quantity
                _listing.quantity -= _quantity;
                totalListingItems[_listing.listingId] = _listing;
            }
            
        } else if (_listing.tokenType == TokenType.ERC721) {
            // Transfer the token to the `_to` address
            IERC721Upgradeable(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, "");

            // Delete the listing off from SynsMarketplace
            delete totalListingItems[_listing.listingId];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the interface supported by a contract (i.e. to check if token is ERC721 or ERC1155)
    function getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC721Upgradeable).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Token must be ERC721 or ERC1155");
        }
    }

    /// @dev Enforces quantity == 1 if tokenType is TokenType.ERC721
    function getSafeQuantity(TokenType _tokenType, uint256 _quantityToCheck) internal pure returns (uint256 safeQuantity) {
        if (_quantityToCheck == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantityToCheck;
        }
    }

    /// @dev Returns an array of `Listings` that are owned by a specific listing's creator
    function getListingsOwnedBy(address _listingCreator) public view returns (Listing[] memory) {
        uint256 totalAmountListedByOwner = getTotalAmountListingBy(_listingCreator);
        uint256 currentIndex;

        Listing[] memory listings = new Listing[](totalAmountListedByOwner);

        for (uint256 i = 0; i < totalListings; i++) {
            if (totalListingItems[i].tokenOwner == _listingCreator) {
                Listing memory listing = totalListingItems[i];
                listings[currentIndex] = listing;
                currentIndex++;
            }
        }
        return listings;
    }


    /// @dev Returns the total listings number an owner has
    function getTotalAmountListingBy(address _listingCreator) public view returns (uint256 total) {
        for (uint256 i = 0; i < totalListings; i++) {
            if (totalListingItems[i].tokenOwner == _listingCreator) {
                total++;
            }
        }
        return total;
    }

    /// @dev Returns an array of `listingIds` that are owned by a specific listing's creator
    function getListingById(uint256 _listingId) external view returns (Listing memory) {
        return totalListingItems[_listingId];
    }

    /// @dev Returns the platform fee recipient and bps
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (synsServiceFeeRecipient, uint16(synsServiceFeeBps));
    }

    /// @dev Returns the ERC1155 token's balance/quantity that an owner has left to create the listing ()
    function getBalanceLeftToList(
        Listing[] memory listings,
        address _assetContract,
        uint256 _tokenId,
        uint256 _totalBalance
    ) public pure returns (uint256 totalBalanceLeft) {

        // assigned totalBalanceLeft
        totalBalanceLeft = _totalBalance;

        // Loop through the array
        for (uint256 i = 0; i < listings.length; i++) {

            // Find out which listing is the target listing by checking `_assetContract` and `_tokenid`.
            if (listings[i].assetContract == _assetContract &&
                listings[i].tokenId == _tokenId
            ) {
                // Calculate `totalBalanceLeft` every time a listing has the same `assetContract` and `tokenId` with `_assetContract` and `_tokenId`
                totalBalanceLeft -= listings[i].quantity;
            }
        }

        return totalBalanceLeft;
    }

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin update the fees on primary sales
    function setPlatformFeeInfo(
        address _platformFeeRecipient, 
        uint256 _platformFeeBps
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_platformFeeBps <= MAX_BPS, "!INVALID BPS - must be less than or equal to 10000.");
        synsServiceFeeBps = uint64 (_platformFeeBps);
        synsServiceFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract. 
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }


    /*///////////////////////////////////////////////////////////////
                            Utilities
    //////////////////////////////////////////////////////////////*/
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

}
