YARN_HARDHAT_BASE=yarn hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
DEFAULT_NETWORK=mumbai
CLUB_SC_ADDRESS=0x50a448b1Dd99E03efDA3bB2aD16c0160D8F53DCf
DONATION_SC_ADDRESS=0xf0BBf6eAA8f4A8353AF947bC7C2453Cc026Ce36a
721_SC_ADDRESS=0x4f06db0BB79B142f8D380f2dE138c66a88438336
1155_SC_ADDRESS=0x36AA51B3BEFA625a6CE2034E316ec870177E70D5
MARKETPLACE_SC_ADDRESS=0x874c22c800D667FB83D8855a50B202F1C4D677f0
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
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(721_SC_ADDRESS) ${SWYL_NFT_NAME} ${SWYL_NFT_SYMBOL} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_ROYALTY_BPS} --show-stack-traces
verify-1155: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(1155_SC_ADDRESS) ${SWYL_NFT_NAME} ${SWYL_NFT_SYMBOL} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_ROYALTY_BPS} --show-stack-traces
verify-marketplace: 
		$(YARN_HARDHAT_BASE) verify --network $(DEFAULT_NETWORK) $(MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### verify all
.PHONY: verify
verify: verify-club verify-donation verify-marketplace verify-721 verify-1155