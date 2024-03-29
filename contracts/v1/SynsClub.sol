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
import { ISynsClub } from "../../interfaces/v1/ISynsClub.sol";

contract SynsClub is
    Initializable,
    ISynsClub,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable
{
     /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice module level info
    bytes32 private constant MODULE_TYPE = bytes32("Syns-Club");
    uint256 private constant VERSION = 1;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 public constant CLUB_OWNER_ROLE = keccak256("CLUB_OWNER_ROLE");

    /// @dev The address of the native token wrapper contract i.e. 0xeee.
    address private immutable nativeTokenWrapper;

    /// @dev The total clubs have ever been created
    uint256 public totalNumberClubs;

    /// @dev The three-day-merci for subscription - 3 days in unix timestamp
    uint public constant THREE_DAY_MERCI = 259200;

    /// @dev The SIX_DAY_EARLY for paying the subscription fee - 6 days in unix timestamp
    uint public constant SIX_DAY_EARLY = 518400;

    /// @dev The 1-month-tier-period to calculate tier's next payment - 1 month (30.44 days) in unix timestamp
    uint public constant TIER_PERIOD = 2629746;

    
    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from an address of a clubId => Club.
    mapping(uint256 => Club) private totalClubs;

    /// @dev Mapping from a clubId => Tier[]
    mapping(uint256 => Tier[]) private totalTiers;

    /// @dev Mapping from a clubId => (tierId => Subscription[])
    mapping(uint256 => mapping(uint256 => Subscription[])) private totalSubscriptions;


    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks where the caller is a Club's onwer
    modifier onlyClubOwnerRole() {
        require(hasRole(CLUB_OWNER_ROLE, _msgSender()), "!CLUB_OWNER");
        _; // move on
    }

    /// @dev Checks where the caller is the owner of the Club
    modifier onlyClubOwner(uint256 _clubId) {
        require(totalClubs[_clubId].clubOwner == _msgSender() , "!CLUB_OWNER");
        _; // move on
    }


    /// @dev Checks whether a Club exists
    modifier onlyExistingClub(uint256 _clubId) {
        require(totalClubs[_clubId].clubOwner != address(0), "CDNE");
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
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Syns Service account
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
        address _defaultAdmin, // original deployer i.e. Syns Service account
        string memory _contrtactURI, // contract level URI
        address[] memory _trustedForwarders
    ) external initializer {
        // Initialize inherited contracts
        __ReentrancyGuard_init(); // block malicious reentrant/nested calls
        __ERC2771Context_init(_trustedForwarders); // init trusted forwarders

        // set platform admin/contract's state info
        contractURI = _contrtactURI;

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin); // grant DEFAULT_ADMIN_ROLE to deployer, i.e. Syns Service account in this case
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
                Club (create-update-cancel) logic
    //////////////////////////////////////////////////////////////*/


    /** 
    * @notice Lets an account start a new Club
    *
    * @dev Start a new Club struct
    */
    function startClub(address _currency) external override {
        // stop a club's owner to create a second club
        require(!hasRole(CLUB_OWNER_ROLE, _msgSender()), "!NOT ALLOWED - account already has a club");

        // grant CLUB_OWNER_ROLE to the caller
        _setupRole(CLUB_OWNER_ROLE, _msgSender());

        // handle clubId and `totalNumberClubs`
        uint256 currentId = totalNumberClubs;

        // start a new Club
        /// @notice see struct `ISynsClub/Club` for more info
        Club memory newClub = Club({
            clubId: currentId,
            clubOwner: _msgSender(),
            date: block.timestamp,
            currency: _currency,
            totalMembers: 0,
            totalActiveMembers: 0
        });

        // update global `toalClubs`
        totalClubs[currentId] = newClub;

        // update global `totalNumberClubs`
        totalNumberClubs++;

        // emit ClubCreated event
        emit ClubCreated(_msgSender(), newClub);
    }

    /** 
    * @notice Lets a Club's owner add a Tier
    *
    * @dev Create a new Tier struct and add it to corresponding Club
    *
    * @param _param     AddTierParam - the parameter that governs the tier to be created.
    *                                  See struct `ISynsClub/AddTierParam` for more info.
    */
    function addTier(AddTierParam memory _param) external override onlyClubOwner(_param.clubId) onlyClubOwnerRole() onlyExistingClub(_param.clubId){
        // param checks
        require(_param.tierFee > 0, "!TIER_FEE - fee must be greater than 0");
        require(_param.sizeLimit > 0, "!SIZE_LIMIT - tier size must be greater than 0");

        // get currentTierId
        Tier[] storage tiers = totalTiers[_param.clubId];
        uint256 currentTierId = tiers.length;


        // initialize newTier struct
        /// @notice see struct `ISynsClub/Tier` for more info
        Tier memory newTier = Tier({
            tierId: currentTierId,
            tierFee: _param.tierFee,
            totalMembers: 0,
            totalActiveMembers: 0,
            sizeLimit: _param.sizeLimit,
            tierData: _param.tierData
        });


        // add newTier to global `totalClubs` array
        tiers.push(newTier);
        totalTiers[_param.clubId] = tiers;

        // emit TierAdded event
        emit TierAdded(currentTierId, _msgSender(), newTier);
    }



    /** 
    * @notice Lets a Club's owner update a Tier
    *
    * @param _param     UpdateTierParam - the parameter that governs the tier to be created.
    *                                  See struct `ISynsClub/UpdateTierParam` for more details.
    */
    function updateTier(UpdateTierParam memory _param) external override onlyClubOwner(_param.clubId) onlyClubOwnerRole() onlyExistingClub(_param.clubId) {
        // param checks
        require(_param.tierFee > 0, "!TIER_FEE - fee must be greater than 0");
        require(_param.sizeLimit > 0, "!SIZE_LIMIT - tier size must be greater than 0");

        // get target Tier array
        Tier[] memory targetClubTiers = totalTiers[_param.clubId];

        // validate if `_param.tierId` points to a valid Tier
        require(_param.tierId < targetClubTiers.length, "!TIER_ID - invalid tierId parameter");

        // get target Tier
        Tier memory targetTier = targetClubTiers[_param.tierId];

        // revert transaction if desired parameters are not any different than targetTier's attributes to save gas
        bool isUpdatable = _param.tierFee != targetTier.tierFee ||
                           _param.sizeLimit != targetTier.sizeLimit ||
                           keccak256(abi.encodePacked(_param.tierData)) != keccak256(abi.encodePacked(targetTier.tierData));
        require(isUpdatable, "!UPDATABLE - nothing new to update");

        // update Tier 
        targetTier.tierFee = _param.tierFee;
        targetTier.sizeLimit = _param.sizeLimit;
        targetTier.tierData = _param.tierData;

        // update global totalClubs
        totalTiers[_param.clubId][_param.tierId] = targetTier;

        // emit the TierUpdated event
        emit TierUpdated(_param.tierId, _msgSender(), targetTier);
    }


    /** 
    * @notice Lets a Club's owner delete a Tier
    *
    * @param _tierId    uint256 - the uid of the tier to be deleted
    */
    function deleteTier(uint256 _clubId, uint256 _tierId) external override onlyClubOwner(_clubId) onlyClubOwnerRole() onlyExistingClub(_clubId) {
        // CANNOT delete a Tier if there are still members in it
        require(getSubscriptionsAt(_clubId, _tierId).length == 0, "!UNDELETEABLE - Cannot delete a Tier if there are still members in it. Please update Tier instead!");

        // get target Tier array
        Tier[] storage targetTiers = totalTiers[_clubId];

        // validate if `_param.tierId` points to a valid Tier
        require(_tierId < targetTiers.length, "!TIER_ID - invalid _param.tierId");

        // shift items toward to cover the target deleted tier => eventually create a duplicating on the last item
        for (uint256 i = _tierId; i < targetTiers.length - 1; i++) {
            targetTiers[i] = targetTiers[i+1];
            totalSubscriptions[_clubId][i] = totalSubscriptions[_clubId][i+1];
        }

        // remove the last item
        targetTiers.pop();
        delete totalSubscriptions[_clubId][targetTiers.length];

        // updated global `totalClubs` state
        totalTiers[_clubId] = targetTiers;

        // @TODO update totalSubscription

        // emit TierDeleted event
        emit TierDeleted(_tierId, _msgSender(), targetTiers);
    }

    // @TODO delete all tiers - Features come in version 2.0


    /** 
    * @notice Lets an account subscribe to a Tier
    *
    * @param _param     SubscriotionAPIParam - the parameter that governs a subscription to be made.
    *                                          See struct `ISynsClub/SubscriptionAPIParam` for more details.
    */
    function subsribe(SubscribeParam memory _param) external payable override nonReentrant onlyExistingClub(_param.clubId){
        // check if the caller has already subscribed and an an active member
        (bool isActiveMember, uint256 existedTierId, uint256 existedSubscriptionId) = checkIsActiveMember(_param.clubId, _msgSender());

        // the caller must not be an active member to subscribe.
        // logic: user that has subscribed before but is not an active member can resubscribe again to the Tier
        require(!isActiveMember, "SUBSCRIBED & ACTIVE");

        // if the user has subscribed but inactive and the existedTierId != type(uint256).max => the subscription already existed.
        // existedTierId must equal _param.tierId
        if (existedTierId != type(uint256).max) {
            require(existedTierId == _param.tierId, "!EXISTED_TIER_ID - subscription has already existed in another Tier");
        }

        // check if tier's sizelimit has already reached the limit if the caller hasn't subscirbed before
        if (existedTierId != type(uint256).max && existedSubscriptionId != type(uint256).max) {
            checkLimit(_param.clubId, _param.tierId);
        }

        // check if the clubOwner matches the clubOwner of the tier
        require(_param.clubOwner == getClubAt(_param.clubId).clubOwner, "!NOT_OWNER - club owner in parameter do not match club owner in club with clubId in parememter");

        // get target Tier array
        Tier[] storage targetTiers = totalTiers[_param.clubId];

        // validate `_param.tierId`
        require(_param.tierId < targetTiers.length, "!TIER_ID - invalid _param.tierId");

        // validate the passed in `_param.tierFee` against the fee of the Tier
        require(_param.tierFee == getTier(_param.clubId, _param.tierId).tierFee, "!TIER_FEE - tierFee parameter does not match the fee of the Tier");
        
        /// @dev validate fund for subscribing tx
        validateFund(_msgSender(), _param.currency, _param.tierFee);

        /// @dev payout the club fee
        payout(_msgSender(), _param.clubOwner, _param.currency, _param.tierFee);

        // check if existedTierId and existedSubscriptionId are valid Ids
        // if valid, updated existed subscription
        if (existedTierId != type(uint256).max && existedSubscriptionId != type(uint256).max) {
            // get the existedSubscription
            Subscription storage existedSubscription = totalSubscriptions[_param.clubId][existedTierId][existedSubscriptionId];

            // update only the dateStart, nextPayment, royaltyStars, and activeMembers fields
            existedSubscription.dateStart = block.timestamp;
            // existedSubscription.nextPayment = block.timestamp + TIER_PERIOD; // unix time for 30.44 days (1 month)
            existedSubscription.nextPayment = block.timestamp + 120;
            existedSubscription.royaltyStars = 1;
            existedSubscription.activeMember =  true;

            // update totalActiveMembers in Tier and Club
            totalClubs[_param.clubId].totalActiveMembers++;
            totalTiers[_param.clubId][existedTierId].totalActiveMembers++;

            // emit ReSubscription event
            emit ReSubscription(existedSubscriptionId, existedTierId, _msgSender(), existedSubscription);

        } else { // New member
            // get current subscriptionId
            Subscription[] storage subscriptions = totalSubscriptions[_param.clubId][_param.tierId];
            uint256 currentSubscriptionId = subscriptions.length;

            // init newSubscription
            /// @notice see struct `ISynsClub/Subscription` for more info 
            Subscription memory newSubscription = Subscription({
                subscriptionId: currentSubscriptionId,
                clubId: _param.clubId,
                tierId: _param.tierId,
                subscriber: _msgSender(),
                dateStart: block.timestamp,
                // nextPayment: block.timestamp + TIER_PERIOD, // unix time for 30.44 days (1 month)
                nextPayment: block.timestamp + 120, // TESTING PURPOSE
                royaltyStars: 1,
                activeMember: true
            });

            // push newSubscriptions to the global state
            subscriptions.push(newSubscription);
            totalSubscriptions[_param.clubId][_param.tierId] = subscriptions;

            // update totalMembers & totalActiveMembers in Tier struct
            totalTiers[_param.clubId][_param.tierId].totalMembers ++;
            totalTiers[_param.clubId][_param.tierId].totalActiveMembers ++;

            // update totalMembers & totalActiveMembers in Club struct
            totalClubs[_param.clubId].totalMembers ++;
            totalClubs[_param.clubId].totalActiveMembers ++;

            // emit NewSubscription event
            emit NewSubscription(currentSubscriptionId, _param.tierId, _msgSender(), newSubscription);
        }
    }


    /** 
    * @notice Lets a subscriber unsubscribe a Tier 
    *
    * @param _clubId            uint256 - the uid of the club holding the tier to be unsubscribed.
    *
    * @param _tierId            uint256 - the uid of the tier to be unsubscribed.
    *
    * @param _subscriptionId    uint256 - the uid of the subscription to be executed.
    */
    function unsubscribe(uint256 _clubId, uint256 _tierId, uint256 _subscriptionId) external override onlyExistingClub(_clubId){
        // checks if caller is a member of the club
        bool isSubscribed = checkIsSubsribed(_clubId, _msgSender());
        require(isSubscribed, "!NOT_SUBSCRIBED");

        // double checks if the caller is the owner of the Subscription
        require(getSubscription(_clubId, _tierId, _subscriptionId).subscriber == _msgSender(), "!SUBSCRIBER - the caller is not the owner of the subscription");

        // validate `_tierId`
        require(_tierId < totalTiers[_clubId].length, "!TIER_ID - invalid _param.tierId");

        // validate of the passed in `_param.subscriptionId` points at a valid subscription
        require(_subscriptionId < getSubscriptionsAt(_clubId, _tierId).length, "!SUBSCRIPTION - subscription not found with `_param.subscriptionId`");

        // check to see if the user was an active user before unsubscribe
        (bool isActive,,) = checkIsActiveMember(_clubId, _msgSender());

        // get targetSubscriptions
        Subscription[] storage targetSubscriptions = totalSubscriptions[_clubId][_tierId];

        // delete the subscription out of the targetSubscriptions array
        for (uint256 i = _subscriptionId; i < targetSubscriptions.length - 1; i++) {
            targetSubscriptions[i] = targetSubscriptions[i+1];
        }
        targetSubscriptions.pop();

        // update global `totalSubscriptions`
        totalSubscriptions[_clubId][_tierId] = targetSubscriptions;


        // update totalMembers in targetTier and targetClub
        totalTiers[_clubId][_tierId].totalMembers --;
        totalClubs[_clubId].totalMembers--;

        // update totalActiveMembers in targetTier and targetClub if this subscriber is an active member
        if (isActive) {
            totalTiers[_clubId][_tierId].totalActiveMembers --;
            totalClubs[_clubId].totalActiveMembers--;
        }
        
        // emit SubscriptionCancel event
        emit SubscriptionCancel(_subscriptionId, _tierId, _msgSender(), targetSubscriptions);
    }


    /**
    * @dev Lets a subscriber pays the Tier fee
    *
    * @param _param     MonthlyTierFeeParam - the parameter that governs the monthly tier fee payment.
    *                                         See struct `ISynsClub/MonthlyTierFeeParam` for more info
    */
    function payMonthlyTierFee(MonthlyTierFeeParam memory _param) external payable nonReentrant onlyExistingClub(_param.clubId) {
        // check if _msgSender() has already subscribed
        bool isSubscribed = checkIsSubsribed(_param.clubId, _msgSender());
        require(isSubscribed, "!SUBSCRIBED");

        // double checks if the caller is the owner of the Subscription
        require(getSubscription(_param.clubId, _param.tierId, _param.subscriptionId).subscriber == _msgSender(), "!SUBSCRIBER - the caller is not the owner of the subscription.");

        // check if the clubOwner matches the clubOwner of the tier
        require(_param.clubOwner == getClubAt(_param.clubId).clubOwner, "!NOT_OWNER - club owner in parameter do not match club owner in club with clubId in parememter.");

        // validate `_param.tierId`
        require(_param.tierId < totalTiers[_param.clubId].length, "!TIER_ID - invalid _param.tierId.");

        // validate the passed in `_param.tierFee` against the fee of the Tier
        require(_param.tierFee == getTier(_param.clubId, _param.tierId).tierFee, "!TIER_FEE - tierFee in parameter does not match the fee of the Tier.");

        // validate of the passed in `_param.subscriptionId` points at a valid subscription
        require(_param.subscriptionId < getSubscriptionsAt(_param.clubId, _param.tierId).length, "!SUBSCRIPTION - subscription not found with `_param.subscriptionId.`");

        // get targetSubscription
        Subscription storage targetSubscription = totalSubscriptions[_param.clubId][_param.tierId][_param.subscriptionId];

        // validate the subscriber can only pay for the Tier Fee no earlier than 6 days unix time until due date
        require(block.timestamp >= targetSubscription.nextPayment - SIX_DAY_EARLY, "!DUE_DATE - Cannot pay more than 6 days earlier than the due date.");

        // validate the subscriber can only pay for the Tier Fee no later than 3 days after due date
        // require(block.timestamp <=targetSubscription.nextPayment + THREE_DAY_MERCI, "!DUE_DATE - Missed the 3-day-merci period. Please re-subscribe again!");
        require(block.timestamp <=targetSubscription.nextPayment + 120, "!DUE_DATE - TESTING PURPOSE");

        /// @dev validate fund for MonthlyFee tx
        validateFund(_msgSender(), _param.currency, _param.tierFee);

        /// @dev payout the club fee
        payout(_msgSender(), _param.clubOwner, _param.currency, _param.tierFee);

        // calculate the next payment based on `isEarly`
        uint256 newNextPayment = targetSubscription.nextPayment + TIER_PERIOD;
        
        // update targetSubscription next payment and royaltyStars
        targetSubscription.nextPayment = newNextPayment;
        targetSubscription.royaltyStars ++;

        // update global `totalSubscriptions`
        totalSubscriptions[_param.clubId][_param.tierId][_param.subscriptionId] = targetSubscription;

        // emit NewSubscription event
        emit MonthlyTierFee(_param.subscriptionId, _param.tierId, _msgSender(), targetSubscription);
    }


    /**
    * @notice Let's a club owner de-activate subscribers who passed the due dates and the three-day-merci period for monthly Tier fee.
    *
    * @notice When executed, subscribers who missed the passed due date will be wipe off and loose all the royaltyStars.
    *
    * @param _clubId    uint256 - the uid of the club being cleaned up.
    *
    * @param _tierId    uint256 - the uid of the tier being cleaned up.
    */
    function deactivateMembersInTier(uint256 _clubId, uint256 _tierId) external override onlyClubOwner(_clubId) onlyClubOwnerRole() onlyExistingClub(_clubId){
        // init totalDeactivatedMembers to keep track of the total number of members got deactivated
        uint256 totalDeactivatedMembers;

        // get current subscriptions of the tier
        Subscription[] storage currentSubscriptions = totalSubscriptions[_clubId][_tierId];

        // set currentTime
        uint256 currentTime = block.timestamp;

        // loop through currentSubscriptions to check which subscription hasn't pay Tier Fee
        for (uint256 i = 0; i < currentSubscriptions.length; i++) {
            // calculate due date based on subscription's `nextPayment` and `merci`
            // uint256 dueDate = currentSubscriptions[i].nextPayment + THREE_DAY_MERCI;
            uint256 dueDate = currentSubscriptions[i].nextPayment;

            // check if this is an active member
            bool isActive = currentSubscriptions[i].activeMember;

            // if currentTime > dueDate => this account is getting deactivated
            if (currentTime > dueDate && isActive) {
                // increment the totalDeactivatedMembers
                totalDeactivatedMembers++;

                // de subscription at index i
                currentSubscriptions[i].royaltyStars = 0;
                currentSubscriptions[i].activeMember = false;
            }
        }

        // update global totalSubscriptions
        totalSubscriptions[_clubId][_tierId] = currentSubscriptions;

        // update totalActiveMembers of club and tier
        totalClubs[_clubId].totalActiveMembers = totalClubs[_clubId].totalActiveMembers - totalDeactivatedMembers;
        totalTiers[_clubId][_tierId].totalActiveMembers = totalTiers[_clubId][_tierId].totalActiveMembers - totalDeactivatedMembers;

        // emit CleanUpClub event
        emit DeactivateMembersInTier(_clubId, _tierId, totalDeactivatedMembers);
    }


    //@TODO feature comes in V2.0: CleanUpTier lets clubOwner clean `inactive` subscriptions


    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
    *  @dev validate the fund of the `_donator`
    *
    *  @param _subscriber           address - the address who is paying for the subscription
    *
    *  @param _currency             address - the address of the currency to buy
    *
    *  @param _totalAmount          uint256 - the total subscription to be transferred
    */
    function validateFund(address _subscriber, address _currency, uint256 _totalAmount) internal {
        // Check buyer owns and has approved sufficient currency for sale
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) { // if currency is native token of a chain
            require(msg.value == _totalAmount, "!FUND - msg.value does not match total club fee");
        } else { // if currency is custom ERC20 token
            validateERC20BalAndAllowance(_subscriber, _currency, _totalAmount);
        }
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
    *                                       that spender (i.e. Club address) will be allowed to spend 
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
    *  @dev Pays out the transaction
    *
    *  @param _subscriber                   address - the address that pays the tier fee amount
    *
    *  @param _clubOwner                    address - the address that receives the tier fee amount
    *
    *  @param _currencyToUse                address - the address of the currency passed in
    *
    *  @param _totalPayoutAmount            uint256 - the total currency amount to pay
    */
    function payout (
        address _subscriber,
        address _clubOwner,
        address _currencyToUse,
        uint256 _totalPayoutAmount
    ) internal {
        // Get nativeTokenWrapper address
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Transfer the total amount from _subscriber to _clubOwner
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse, 
            _subscriber, 
            _clubOwner, 
            _totalPayoutAmount,
            _nativeTokenWrapper
        );
    }

    /** 
    * @dev Returns the subscriptionId based on caller address
    *
    * @param _clubId        uint256 - the uid of the club. 
    *
    * @param _subscriber    address - address of the caller
    *
    * @return uint256       subscriptionId if subsribed or type(uint256).max if unsubscribe
    */
    function getSubscriptionId(uint256 _clubId, address _subscriber) internal view returns (uint256) {
        Tier[] memory targetTiers = totalTiers[_clubId];

        for (uint256 i = 0; i < targetTiers.length; i++) {
            Subscription[] memory currentSubscriptions = totalSubscriptions[_clubId][i];

            for (uint256 j = 0; j < currentSubscriptions.length; j++) {
                if (currentSubscriptions[j].subscriber == _subscriber) {
                    return j;
                }
            }
        }
        return type(uint256).max;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Checkers
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Checks if a subscriber has already subscribed to a club
    *
    * @param _clubId        uint256 - the uid of the club.
    *
    * @param _subscriber    address - the address of the subscribing caller.
    *
    * @return bool          true if the subscriber has already subscribed and vice versa.
    */
    function checkIsSubsribed(uint256 _clubId, address _subscriber) public view returns (bool) {
        Tier[] memory targetTiers = totalTiers[_clubId];

        for (uint256 i = 0; i < targetTiers.length; i++) {
            Subscription[] memory currentSubscriptions = totalSubscriptions[_clubId][i];

            for (uint256 j = 0; j < currentSubscriptions.length; j++) {
                if (currentSubscriptions[j].subscriber == _subscriber) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
    * @dev Checks if the tier's sizeLimit has reached the max limit
    *
    * @param _clubId        uint256 - the uid of the club.
    *
    * @param _tierId        uint256 - the uid of the tier.
    */
    function checkLimit(uint256 _clubId, uint256 _tierId) public view {
        // get target tier
        Tier memory targetTier = getTier(_clubId, _tierId);

        // Compare total members with sizeLimit
        require(targetTier.totalMembers < targetTier.sizeLimit,"!SIZE_LIMIT");
    }
    

    /**
    * @dev Checks if a subscriber is an active member by checking if the subscriber has paid the Tier fee on time
    * 
    * @param _clubId            uint256 - the uid of the club.
    *
    * @param _member            address - the address of the member being checkd against
    *
    * @return bool              true if the caller is an active member and vice versa
    *
    * @return uint256           tierId
    *
    * @return uint256           subscriptionId
    */
    function checkIsActiveMember(uint256 _clubId, address _member) public view returns (bool, uint256, uint256) {
        Tier[] memory targetTiers = totalTiers[_clubId];

        for (uint256 i = 0; i < targetTiers.length; i++) {
            Subscription[] memory currentSubscriptions = totalSubscriptions[_clubId][i];

            for (uint256 j = 0; j < currentSubscriptions.length; j++) {
                if (currentSubscriptions[j].subscriber == _member) {
                    // if (block.timestamp <= currentSubscriptions[j].nextPayment + THREE_DAY_MERCI) {
                    if (block.timestamp <= currentSubscriptions[j].nextPayment) {
                        return (true, i, j);
                    } else {
                        return (false, i, j);
                    }
                }
            }
        }
        return (false, type(uint256).max, type(uint256).max);
    }


    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns a Club by `_clubOwner`
    function getClubAt(uint256 _clubId) public view returns (Club memory) {
        return totalClubs[_clubId];
    }

    /// @dev Returns an array of Tier based on `_clubId`
    function getTiersAt(uint256 _clubId) public view onlyExistingClub(_clubId) returns (Tier[] memory) {
        return totalTiers[_clubId];
    }

    /// @dev Returns a specific Tier based on `_clubId` & `_tierId`
    function getTier(uint256 _clubId, uint256 _tierId) public view onlyExistingClub(_clubId) returns (Tier memory) {
        return totalTiers[_clubId][_tierId];
    }

    /// @dev Returns an array of Subscription based on `_clubId` & `_tierId`
    function getSubscriptionsAt(uint256 _clubId, uint256 _tierId) public view onlyExistingClub(_clubId) returns (Subscription[] memory) {
        return totalSubscriptions[_clubId][_tierId];
    }

    /// @dev Returns a specific Subscription based on `_clubId`, `_tierId` & `_subscriptionId`
    function getSubscription(uint256 _clubId, uint256 _tierId, uint256 _subscriptionId) public view onlyExistingClub(_clubId) returns (Subscription memory) {
        return totalSubscriptions[_clubId][_tierId][_subscriptionId];
    }

    /// @dev Returns the duration one subscriber has been subscribing a Tier
    function getRoyaltyDuration(uint256 _clubId, uint256 _tierId, uint256 _subscriptionId) public view onlyExistingClub(_clubId) returns (uint256) {
        return block.timestamp - getSubscription(_clubId, _tierId, _subscriptionId).dateStart;
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