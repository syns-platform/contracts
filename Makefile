YARN_HARDHAT_BASE=yarn hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
NAVTIVE_TOKEN_WRAPPER=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
SWYL_NFT_NAME=Support-Who-You-Love
SWYL_NFT_SYMBOL=SWYL
SWYL_NFT_SERVICE_RECIPIENT=0xFBAaB608AE4e0ED1ec86bEF8Ba689f064bFFe560
SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS=2000

## MUMBAI NETWORK 
MUMBAI_NETWORK=mumbai
MUMBAI_CLUB_SC_ADDRESS=0xbaD30b83BCca1895CBF3DAa259659fDceC8eA480
MUMBAI_DONATION_SC_ADDRESS=0x186cd15DbdF44421D3453dbC897B4b36fecD0F73
MUMBAI_721_SC_ADDRESS=0x16A50894fcf101c1952F5f430b4Da8cBe488357b
MUMBAI_1155_SC_ADDRESS=0x17756A4D1AcCa1E85A2993eA1C1E25Cf3c925d7C
MUMBAI_MARKETPLACE_SC_ADDRESS=0x77d4e7a738e6e594B4A3F9BA8d49527EDD25d7Db


## GOERLI NETWORK
GOERLI_NETWORK=goerli
GOERLI_CLUB_SC_ADDRESS=0x81238B62F7B51871B20d13cd8Ab4B3456C50d155
GOERLI_DONATION_SC_ADDRESS=0xD77A9F361d76e407cDC830395F8D9BFbf75E2c98
GOERLI_721_SC_ADDRESS=0xD77a1d4b16e029150E1cF3650D8AfbBF55f44a52
GOERLI_1155_SC_ADDRESS=0x8dC33f3Df601311994608B08173E6b525c798cA7
GOERLI_MARKETPLACE_SC_ADDRESS=0xE8E21801faee5B6aa714fd38E72838C341EaF551

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
mumbai-deploy: 
		$(YARN_HARDHAT_BASE) run $(DEPLOY_SCRIPT_PATH) --network $(MUMBAI_NETWORK)
goerli-deploy: 
		$(YARN_HARDHAT_BASE) run $(DEPLOY_SCRIPT_PATH) --network $(GOERLI_NETWORK)


## VERIFY SCs

### MUMBAI
mumbai-verify-club: 
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_CLUB_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
mumbai-verify-donation: 
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_DONATION_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
mumbai-verify-721: 
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_721_SC_ADDRESS) --show-stack-traces
mumbai-verify-1155: 
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_1155_SC_ADDRESS) --show-stack-traces
mumbai-verify-marketplace: 
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### GOERLI
goerli-verify-club: 
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_CLUB_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
goerli-verify-donation: 
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_DONATION_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
goerli-verify-721: 
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_721_SC_ADDRESS) --show-stack-traces
goerli-verify-1155: 
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_1155_SC_ADDRESS) --show-stack-traces
goerli-verify-marketplace: 
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SWYL_NFT_SERVICE_RECIPIENT} ${SWYL_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### verify all
mumbai-verify: mumbai-verify-club mumbai-verify-donation mumbai-verify-marketplace mumbai-verify-721 mumbai-verify-1155

goerli-verify: goerli-verify-club goerli-verify-donation goerli-verify-marketplace goerli-verify-721 goerli-verify-1155