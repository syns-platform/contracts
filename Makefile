YARN_HARDHAT_BASE=yarn hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
NAVTIVE_TOKEN_WRAPPER=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
SYNS_NFT_NAME=Spark-Your-Noble-Story
SYNS_NFT_SYMBOL=SYNS
SYNS_NFT_SERVICE_RECIPIENT=0x0851072d7bB726305032Eff23CB8fd22eB74c85B
SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS=2000

## MUMBAI NETWORK 
MUMBAI_NETWORK=mumbai
MUMBAI_CLUB_SC_ADDRESS=0x2A4E26C5FC5CA26E9ca04DbAc64d54F3D99DD3Ce
MUMBAI_DONATION_SC_ADDRESS=0x7CEA07382bfad656945F990BBfB872A255f95A56
MUMBAI_721_SC_ADDRESS=0xfDe11549f6133020721975BAc8A054EF6FCb4C0f
MUMBAI_1155_SC_ADDRESS=0x8aa884a1297f10C5B9Daa48Cd8e85Acb4C713933
MUMBAI_MARKETPLACE_SC_ADDRESS=0x990D76F1190D5098928cd2cAcCe0a2C9293EfBa8


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
		$(YARN_HARDHAT_BASE) verify --network $(MUMBAI_NETWORK) $(MUMBAI_MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SYNS_NFT_SERVICE_RECIPIENT} ${SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

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
		$(YARN_HARDHAT_BASE) verify --network $(GOERLI_NETWORK) $(GOERLI_MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SYNS_NFT_SERVICE_RECIPIENT} ${SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### verify all
mumbai-verify: mumbai-verify-club mumbai-verify-donation mumbai-verify-marketplace mumbai-verify-721 mumbai-verify-1155

goerli-verify: goerli-verify-club goerli-verify-donation goerli-verify-marketplace goerli-verify-721 goerli-verify-1155