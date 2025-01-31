PNPM_HARDHAT_BASE=pnpm hardhat
DEPLOY_SCRIPT_PATH=./deploy-scripts/v1/
NAVTIVE_TOKEN_WRAPPER=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
SYNS_NFT_NAME=Spark-Your-Noble-Story
SYNS_NFT_SYMBOL=SYNS
SYNS_NFT_SERVICE_RECIPIENT=0x0851072d7bB726305032Eff23CB8fd22eB74c85B
SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS=2000

## MUMBAI NETWORK 
HEDERA_TESTNET=hedera_testnet
HEDERA_CLUB_SC_ADDRESS=0x2A4E26C5FC5CA26E9ca04DbAc64d54F3D99DD3Ce
HEDERA_DONATION_SC_ADDRESS=0x7CEA07382bfad656945F990BBfB872A255f95A56
HEDERA_721_SC_ADDRESS=0xfDe11549f6133020721975BAc8A054EF6FCb4C0f
HEDERA_1155_SC_ADDRESS=0x8aa884a1297f10C5B9Daa48Cd8e85Acb4C713933
HEDERA_MARKETPLACE_SC_ADDRESS=0x990D76F1190D5098928cd2cAcCe0a2C9293EfBa8



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
		pnpm i

## COMPILE SCs
.PHONY: compile
compile:
		${PNPM_HARDHAT_BASE} compile

## DEPLOY SCs
hedera-deploy: 
		$(PNPM_HARDHAT_BASE) run $(DEPLOY_SCRIPT_PATH) --network $(HEDERA_TESTNET)


## VERIFY SCs

### MUMBAI
hedera-verify-club: 
		$(PNPM_HARDHAT_BASE) verify --network $(HEDERA_TESTNET) $(HEDERA_CLUB_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
hedera-verify-donation: 
		$(PNPM_HARDHAT_BASE) verify --network $(HEDERA_TESTNET) $(HEDERA_DONATION_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} --show-stack-traces
hedera-verify-721: 
		$(PNPM_HARDHAT_BASE) verify --network $(HEDERA_TESTNET) $(HEDERA_721_SC_ADDRESS) --show-stack-traces
hedera-verify-1155: 
		$(PNPM_HARDHAT_BASE) verify --network $(HEDERA_TESTNET) $(HEDERA_1155_SC_ADDRESS) --show-stack-traces
hedera-verify-marketplace: 
		$(PNPM_HARDHAT_BASE) verify --network $(HEDERA_TESTNET) $(HEDERA_MARKETPLACE_SC_ADDRESS) ${NAVTIVE_TOKEN_WRAPPER} ${SYNS_NFT_SERVICE_RECIPIENT} ${SYNS_NFT_DEFAULT_PLATOFRM_FREE_BPS} --show-stack-traces

### verify all
hedera-verify: hedera-verify-club hedera-verify-donation hedera-verify-marketplace hedera-verify-721 hedera-verify-1155
