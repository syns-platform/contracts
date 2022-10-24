/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Honor: OpenZeppelin
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";

//  ==========  Internal imports    ==========
import { ISwylClub } from "../../interfaces/v1/ISwylClub.sol";

contract SwylDonation is
    Initializable,
    ISwylClub,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable
{
     /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice module level info
    bytes32 private constant MODULE_TYPE = bytes32("Swyl-Club");
    uint256 private constant VERSION = 1;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 public constant CLUB_OWNER_ROLE = keccak256("CLUB_OWNER_ROLE");

    /// @dev The address of the native token wrapper contract i.e. 0xeee.
    address private immutable nativeTokenWrapper;

    
    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from an address of a Club's owner => Club.
    mapping(address => Club) private totalClubs;


    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks where the caller is a Club's onwer
    modifier onlyClubOwnerRole(address clubOwner) {
        require(hasRole(CLUB_OWNER_ROLE, _msgSender()), "!CLUB_OWNER");
        _; // move on
    }

    /// @dev Checks where the caller is the owner of the Club
    modifier onlyClubOwner(address clubOwner) {
        require(totalClubs[_msgSender()].clubOwner == _msgSender() , "!CLUB_OWNER");
        _; // move on
    }


    /// @dev Checks where a Club exists
    modifier onlyExistingClub(address clubOwner) {
        require(totalClubs[clubOwner].clubOwner != address(0), "DNE");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/


    /** 
    * @dev This contract utilizes the @openzeppelin/upgradeable pluggin and then will be deployed behind a proxy.
    *       A proxied contract doesn't make use of a constructor and the logic in a constructor got moved into 
    *       an external initializer function.
    *
    * @notice deploying to a proxy, constructor won't be in use.
    */ 
    constructor (address _nativeTokenWrapper) initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls

        // set nativeTokenWrapper
        nativeTokenWrapper = _nativeTokenWrapper;


         // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Swyl Service account
        _setupRole(CLUB_OWNER_ROLE, address(0));
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
        address[] memory _trustedForwarders
    ) external initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls
        __ERC2771Context_init(_trustedForwarders); // init trusted forwarders

        // set platform admin/contract's state info
        contractURI = _contrtactURI;

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Swyl Service account in this case
        _setupRole(CLUB_OWNER_ROLE, address(0)); // grant LISTER_ROLE to address 0x000
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
                Donation (create-update-cancel) logic
    //////////////////////////////////////////////////////////////*/


    /** 
    * @notice Lets an account start a new Club
    *
    * @dev Start a new Club struct
    */
    function startClub(address _currency) external override {
        // stop a club's owner to create a second club
        require(!hasRole(CLUB_OWNER_ROLE, _msgSender()), "!NOT ALOOWED - account already has a club");

        // grant CLUB_OWNER_ROLE to the caller
        _setupRole(CLUB_OWNER_ROLE, _msgSender());

        // start a new Club
        Tier[] memory tiers;
        Club memory newClub = Club({
            clubOwner: _msgSender(),
            date: block.timestamp,
            currency: _currency,
            tiers: tiers
        });

        // update global `toalClubs`
        totalClubs[_msgSender()] = newClub;

        // emit ClubCreated event
        emit ClubCreated(_msgSender(), newClub);
    }

    /** 
    * @notice Lets a Club's owner add a Tier
    *
    * @dev Create a new Tier struct and add it to corresponding Club
    *
    * @param _param     TierAPIParam - the parameter that governs the tier to be created.
    *                                  See struct `TierAPIParam` for more info.
    */
    function addTier(AddTierParam memory _param) external override onlyClubOwner(_msgSender()) onlyClubOwnerRole(_msgSender()) onlyExistingClub(_msgSender()){
        // param checks
        require(_param.tierFee > 0, "!TIER_FEE - fee must be greater than 0");
        require(_param.sizeLimit > 0, "!SIZE_LIMIT - tier size must be greater than 0");


        // get currentTierId
        uint256 currentTierId = totalClubs[_msgSender()].tiers.length;

        // get members array
        address[] memory members;

        // initialize newTier struct
        Tier memory newTier = Tier({
            tierId: currentTierId,
            tierFee: _param.tierFee,
            members: members,
            sizeLimit: _param.sizeLimit,
            tierData: _param.tierData
        });


        // add newTier to global `totalClubs` array
        totalClubs[_msgSender()].tiers.push(newTier);

        // emit TierAdded event
        emit TierAdded(currentTierId, _msgSender(), newTier);
    }



    /** 
    * @notice Lets a Club's owner update a Tier
    *
    * @param _param     TierAPIParam - the parameter that governs the tier to be created.
    *                                  See struct `TierAPIParam` for more details.
    */
    function updateTier(UpdateTierParam memory _param) external override onlyClubOwner(_msgSender()) onlyClubOwnerRole(_msgSender()) onlyExistingClub(_msgSender()) {
        // param checks
        require(_param.tierFee > 0, "!TIER_FEE - fee must be greater than 0");
        require(_param.sizeLimit > 0, "!SIZE_LIMIT - tier size must be greater than 0");

        // get target Club
        Club memory targetClub = totalClubs[_msgSender()];

        // validate if `_param.tierId` points to a valid Tier
        require(_param.tierId < targetClub.tiers.length, "!TIER_ID - invalid _param.tierId");

        // get target Tier
        Tier memory targetTier = targetClub.tiers[_param.tierId];

        // revert transaction if desired parameters are not any different than targetTier's attributes to save gas
        bool isUpdatable = _param.tierFee != targetTier.tierFee ||
                           keccak256(abi.encodePacked(_param.tierData)) != keccak256(abi.encodePacked(targetTier.tierData)) || 
                           _param.sizeLimit != targetTier.sizeLimit;
        require(isUpdatable, "!UPDATABLE - nothing new to update");

        // update Tier 
        targetTier.tierFee = _param.tierFee;
        targetTier.sizeLimit = _param.sizeLimit;
        targetTier.tierData = _param.tierData;

        // update global totalClubs
        totalClubs[_msgSender()].tiers[_param.tierId] = targetTier;

        // emit the TierUpdated event
        emit TierUpdated(_param.tierId, _msgSender(), targetTier);
    }


    /** 
    * @notice Lets a Club's owner delete a Tier
    *
    * @param _tierId    uint256 - the uid of the tier to be deleted
    */
    function deleteTier(uint256 _tierId) external override onlyClubOwner(_msgSender()) onlyClubOwnerRole(_msgSender()) onlyExistingClub(_msgSender()) {
         // get target Club
        Club storage targetClub = totalClubs[_msgSender()];

        // validate if `_param.tierId` points to a valid Tier
        require(_tierId < targetClub.tiers.length, "!TIER_ID - invalid _param.tierId");

        // get the array of Tier
        Tier[] storage tiers = targetClub.tiers;

        // shift items toward to cover the target deleted tier => eventually create duplicating last item
        for (uint256 i = _tierId; i < tiers.length - 1; i++) {
            tiers[i] = tiers[i+1];
        }

        // remove the last item
        tiers.pop();

        // updated global `totalClubs` state
        totalClubs[_msgSender()].tiers = tiers;

        // emit TierDeleted event
        emit TierDeleted(_tierId, _msgSender(), tiers);
    }


    /** 
    * @notice Lets an account subscribe to a Tier
    *
    * @param _param     SubscriotionAPIParam - the parameter that governs a subscription to be made.
    *                                          See struct `SubscriptionAPIParam` for more details.
    */
    function subsribe(SubscriotionAPIParam memory _param) external payable override {}


    /** 
    * @notice Lets a subscriber unsubscribe a Tier 
    *
    * @param _clubId     uint256 - the uid of the club holding the tier to be unsubscribed.
    *
    * @param _tierId     uint256 - the uid of the tier to be unsubscribed.
    */
    function unsubscribe(uint256 _clubId, uint256 _tierId) external override {}




    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    
    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns a Club by `_clubOwner`
    function getClubOwnedBy(address _clubOwner) public view returns (Club memory) {
        return totalClubs[_clubOwner];
    }


    /// @dev Returns an array of Tier that a `_clubOwner` has
    function getTiersBy(address _clubOwner) public view returns (Tier[] memory) {
        return totalClubs[_clubOwner].tiers;
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