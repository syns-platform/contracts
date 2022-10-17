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
import { ISwylMarketplace } from "../../interfaces/v1/ISwylMarketplace.sol";


contract SwylMarketplace is 
    Initializable,
    ISwylMarketplace,
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
    bytes32 private constant MODULE_TYPE = bytes32("Swyl-Marketplace");
    uint256 private constant VERSION = 1;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The max bps of the contract. 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

     /// @dev The address that receives all platform fees from all sales.
    address private swylServiceFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint64 private swylServiceFeeBps;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The address of the native token wrapper contract i.e. 0xeee.
    address private immutable nativeTokenWrapper;

    /// @dev Total number of listings ever created in the marketplace.
    uint256 public totalListings;


    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/
    
    /// @dev Mapping from uid of listing => listing info. All the listings on the marketplace
    mapping(uint256 => Listing) public totalListingItems;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    mapping(uint256 => mapping(address => OfferParameters)) public offers;

    /// @dev Mapping from msg.sender address => an array of listingIds
    mapping(address => uint256[]) public ownListings;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is the listing creator.
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
        address _platformFeeRecipient, // swylServiceFeeRecipient
        uint256 _platformFeeBps //swylServiceFeeBps
    ) initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls

        // set nativeTokenWrapper
        nativeTokenWrapper = _nativeTokenWrapper;

        // set platform admin/contract's state info
        swylServiceFeeRecipient = _platformFeeRecipient;
        swylServiceFeeBps = uint64(_platformFeeBps);

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Swyl Service account in this case
        _setupRole(LISTER_ROLE, address(0)); // grant LISTER_ROLE to address 0x000
        _setupRole(ASSET_ROLE, address(0)); // grant ASSET_ROLE to address 0x000
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
        address _defaultAdmin, // original deployer i.e. Swyl Service account
        string memory _contrtactURI, // contract level URI
        address[] memory _trustedForwarders,
        address _platformFeeRecipient, // swylServiceFeeRecipient
        uint256 _platformFeeBps //swylServiceFeeBps
    ) external initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls
        __ERC2771Context_init(_trustedForwarders); // init trusted forwarders

        // set platform admin/contract's state info
        contractURI = _contrtactURI;
        swylServiceFeeRecipient = _platformFeeRecipient;
        swylServiceFeeBps = uint64(_platformFeeBps);

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Swyl Service account in this case
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
        address, // operator    - The address which initiated the transfer, i.e. SwylMarketplace in this case
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
        address, // operator            - The address which initiated the batch transfer (i.e. msg.sender), i.e. SwylMarketplace in this case
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
        address, // operator        - The address which initiated the batch transfer (i.e. msg.sender), i.e. SwylMarketplace in this case
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
                Listing (create-update-delete) logic
    //////////////////////////////////////////////////////////////*/

    /**
    *@dev Lets a token owner create an item to list on the marketplace (listing). 
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
    */ 
    function createListing(
        address _assetContract,
        uint256 _tokenId,
        uint256 _listingDuration,
        uint256 _quantityToList,
        address _currencyToAccept,
        uint256 _buyoutPricePerToken
    ) external override {
        // Get next listingId to list
        uint256 listingId = totalListings;
        totalListings += 1;

        // Get token info
        address tokenOwner = _msgSender();
        TokenType listTokenType = getTokenType(_assetContract);
        uint tokenAmountToList = getSafeQuantity(listTokenType, _quantityToList);

        // Check if tokenAmountToList is valid
        require(tokenAmountToList > 0, "INVALID QUANTITY - must be greater than 0");

        // Check roles
        require(hasRole(LISTER_ROLE, address(0)) || hasRole(LISTER_ROLE, _msgSender()), "INVALID ROLE - account must have LISTER_ROLE role");
        require(hasRole(ASSET_ROLE, address(0)) || hasRole(ASSET_ROLE, _assetContract), "INVALID ROLE - account must have ASSET_ROLE role");


        // validate token's ownership and approval
        validateOwnershipAndApproval(tokenOwner, _assetContract, _tokenId, tokenAmountToList, listTokenType);

        // create new listing
        Listing memory newListing = Listing({
            listingId: listingId,
            tokenOwner: tokenOwner,
            assetContract: _assetContract,
            tokenId: _tokenId,
            startSale: block.timestamp, // set to current time
            endSale: block.timestamp + _listingDuration,
            quantity: tokenAmountToList,
            currency: _currencyToAccept,
            buyoutPricePerToken: _buyoutPricePerToken,
            tokenType: listTokenType
        });

        // adds listing to mapping totalListingItems
        totalListingItems[listingId] = newListing;

        // adds listing to mapping ownListings to keep track of who owns which listings
        uint256[] storage listingIdsOwnedByTokenOwner = ownListings[tokenOwner];
        listingIdsOwnedByTokenOwner.push(newListing.listingId);
        ownListings[tokenOwner] = listingIdsOwnedByTokenOwner;

        // emit ListingAdded event
        emit ListingAdded(listingId, newListing.assetContract, tokenOwner, newListing);
    }


    /**
    * @dev Lets a listing creator update the listing's metadata. More info can be found in interfaces/v1/ISwylMarketplace.sol
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
    */
    function updateListing(
        uint256 _listingId, 
        uint256 _quantityToList, 
        uint256 _buyoutPricePerToken, 
        address _currencyToAccept, 
        uint256 _startSale,
        uint256 _listingDuration
    ) external override onlyListingOwner(_listingId){}


    /**
    * @dev Lets a listing creator cancel a listing.
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
    */
    function cancelDirectListing(uint256 _listingId) external override onlyListingOwner(_listingId){}


    /*///////////////////////////////////////////////////////////////
                    Direct lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Lets someone buy a given quantity of tokens from a direct listing by paying the price 
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
    */
    function buy(
        uint256 _listingId, 
        address _buyer, 
        uint256 _quantity, 
        address _currency, 
        uint256 _totalPrice
    ) external payable override nonReentrant onlyExistingListing(_listingId) {}


    /**
    * @dev Lets someone make an offer to an existing direct listing
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
    */
    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        address _currency, 
        uint256 _pricePerToken, 
        uint256 _offerDuration
    ) external payable nonReentrant onlyExistingListing(_listingId) {}

    /**
    * @dev Lets a listing's creator accept an offer to their direct listing
    *
    * NOTE More info can be found in interfaces/v1/ISwylMarketplace.sol
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

    /// @dev validate that `_tokenOwner` owns and has approved SwylMarketplace to transfer NFTs
    function validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal 
    view 
    {
        // get SwylMarketplace's address
        address SwylMarketplaceAddress = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid = 
                IERC1155Upgradeable(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity && // check if owner has enough balance to list
                IERC1155Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, SwylMarketplaceAddress); // check if owner approved SwylMarketplaceAddress to list their NFTs
        } else if (_tokenType == TokenType.ERC721) {
            isValid = 
                IERC721Upgradeable(_assetContract).ownerOf(_tokenId) == _tokenOwner && // check if the _tokenOwner owns the token
                (IERC721Upgradeable(_assetContract).getApproved(_tokenId) == SwylMarketplaceAddress || // check if SwylMarkplace is appeared in token's approve list
                IERC721Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, SwylMarketplaceAddress)); // check if _tokenOwner approves SwylMarketplace
        }
        require(isValid, "!INVALID OWNERSHIP AND APPROVAL");
    }


    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the platform fee bps and recipient
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (swylServiceFeeRecipient, uint16(swylServiceFeeBps));
    }

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
    function getSafeQuantity(
        TokenType _tokenType, 
        uint256 _quantityToCheck
    ) internal pure returns (uint256 safeQuantity) {
        if (_quantityToCheck == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantityToCheck;
        }
    }


    /// @dev Returns an array of `listingIds` that are owned by a specific listing's creator
    function getListingsOwnedBy(address _listingCreator) external view returns (uint256[] memory) {
        return ownListings[_listingCreator];
    }

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin update the fees on primary sales
    function setPlatformFeeInfo(
        address _platformFeeRecipient, 
        uint256 _platformFeeBps
    ) external onlyRole(DEFAULT_ADMIN_ROLE){}

    /// @dev Sets contract URI for the storefront-level metadata of the contract. 
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {}


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
