YARN_HARDHAT_BASE=yarn hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
DEFAULT_NETWORK=mumbai
CLUB_SC_ADDRESS=
DONATION_SC_ADDRESS=
MARKETPLACE_SC_ADDRESS=
721_SC_ADDRESS=
1155_SC_ADDRESS=


## Clean dev environment

.PHONY: clean
clean: 
		@echo Deep cleaning dev environment...
		@echo Purging ./artifacts...
		rm -rf ./artifacts
		@echo Purging ./cache...
		rm -rf ./cache
		@echo Purging ./node_modules...
		rm -rf ./node_modules
		@echo Reinstalling dependencies modules
		yarn


## COMPILE SCs
.PHONY: compile
compile: 
		${YARN_HARDHAT_BASE} compile

## DEPLOY SCs
.PHONY: deploy
deploy: 
		$(YARN_HARDHAT_BASE) run $(DEPLOY_SCRIPT_PATH) --network $(DEFAULT_NETWORK)


## VERIFY SCs
verify-club: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(CLUB_SC_ADDRESS)
verify-donation: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(DONATION_SC_ADDRESS)
verify-marketplace: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(MARKETPLACE_SC_ADDRESS)
verify-721: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(721_SC_ADDRESS)
verify-1155: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(1155_SC_ADDRESS)

### verify all
verify-index: verify-club verify-donation verify-marketplace verify-721 verify-1155