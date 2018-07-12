import json
import sys

from ethereum import utils
from ethereum.tester import TransactionFailed
import pytest
import web3
from populus.wait import Wait

from omg_contract_codes import OMGTOKEN_CONTRACT_ABI, OMGTOKEN_CONTRACT_BYTECODE

HUGE_AMOUNT = 10**36
LARGE_AMOUNT = utils.denoms.ether
MEDIUM_AMOUNT = 10000
SMALL_AMOUNT = 10
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
DEAD_ADDRESS = '0x000000000000000000000000000000000000dead'

def deploy(web3, ContractClass):
    deploy_tx = ContractClass.deploy()
    Wait(web3).for_receipt(deploy_tx)
    deploy_receipt = web3.eth.getTransactionReceipt(deploy_tx)
    return ContractClass(address=deploy_receipt['contractAddress'])

@pytest.fixture()
def omg_token(chain, accounts):
    
    owner = accounts[0]
    
    contract_class = chain.web3.eth.contract(abi=json.loads(OMGTOKEN_CONTRACT_ABI),
                                             bytecode = OMGTOKEN_CONTRACT_BYTECODE
    )

    token = deploy(chain.web3, contract_class)
    for validator in accounts:
        chain.wait.for_receipt(
            token.transact({'from': owner}).mint(validator, HUGE_AMOUNT)
        )
    chain.wait.for_receipt(
        token.transact({'from': owner}).finishMintint()
    )
    return token

def test_sample():
    assert 1 == 1
 
