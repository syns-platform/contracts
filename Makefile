YARN_HARDHAT_BASE=yarn hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
DEFAULT_NETWORK=mumbai
CLUB_SC_ADDRESS=0xd6d8218BB9f70b270302F2b783A2ab042D97082D
DONATION_SC_ADDRESS=0x5629F7BAB3cDbDdB1ABd58cbBCE9F17a70039760
721_SC_ADDRESS=0xa03063e55AbE857b31Da7218c1d799d8969F2819
1155_SC_ADDRESS=0x23Ad947cc690A4cc1C5Caef2fCa1fa531Ccf969F
MARKETPLACE_SC_ADDRESS=0xA54e79f3936d88A6d725F1174743F57636aF1345
NAVTIVE_TOKEN_WRAPPER=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
SWYL_NFT_NAME=Support-Who-You-Love
SWYL_NFT_SYMBOL=SWYL
SWYL_NFT_SERVICE_RECIPIENT=0xfA0D311F4f3be671f414c2B3b998323eC25c5AFD
SWYL_NFT_DEFAULT_ROYALTY_BPS=1000
SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS=2000

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
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(CLUB_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
verify-donation: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(DONATION_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
verify-721: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(721_SC_ADDRESS) --show-stack-traces
verify-1155: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(1155_SC_ADDRESS) --show-stack-traces
verify-marketplace: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### verify all
.PHONY: verify
verify: verify-club verify-donation verify-marketplace verify-721 verify-1155

verify-erc: verify-721 verify-1155