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
DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD'


def getAddress(web3, OMGContractClass):
    deploy_tx = OMGContractClass.deploy()
    Wait(web3).for_receipt(deploy_tx)
    deploy_receipt = web3.eth.getTransactionReceipt(deploy_tx)
    return deploy_receipt['contractAddress']


def mintToken(chain, token, accounts, owner):

    used_accounts = accounts[0:1]

    for validator in used_accounts:
        chain.wait.for_receipt(
            token.transact({'from': owner}).mint(validator, HUGE_AMOUNT)
        )
    chain.wait.for_receipt(
        token.transact({'from': owner}).finishMinting()
    )


def deploy_fee_burner(omg_address, chain, owner):
    fee_burner, _ = chain.provider.get_or_deploy_contract('FeeBurner',
                                                          deploy_transaction={
                                                              'from': owner},
                                                          deploy_args=[omg_address]
                                                          )
    return fee_burner


@pytest.fixture()
def operator(accounts):
    return accounts[0]

@pytest.fixture()
def non_operator(operator, accounts):
    for user in accounts:
        if user != operator:
            return user

@pytest.fixture()
def OMGContractClass(web3):
    return web3.eth.contract(
        abi=json.loads(OMGTOKEN_CONTRACT_ABI),
        bytecode=OMGTOKEN_CONTRACT_BYTECODE
    )


@pytest.fixture()
def omg_token(chain, accounts, OMGContractClass):

    owner = accounts[0]

    contractAddress = getAddress(chain.web3, OMGContractClass)
    token = OMGContractClass(address=contractAddress)

    mintToken(chain, token, accounts, owner)

    token.transact({'from': owner}).transferOwnership(DEAD_ADDRESS)

    return token


@pytest.fixture()
def other_token(chain, accounts, OMGContractClass):

    owner = accounts[0]

    contractAddress = getAddress(chain.web3, OMGContractClass)
    token = OMGContractClass(address=contractAddress)

    mintToken(chain, token, accounts, owner)

    token.transact({'from': owner}).transferOwnership(DEAD_ADDRESS)

    return token


@pytest.fixture()
def fee_burner(omg_token, chain, operator):

    fee_burner = deploy_fee_burner(omg_token.address, chain, operator)

    fee_burner.transact({'from': operator}).addSupportFor(ZERO_ADDRESS, 1, 1)

    return fee_burner


# TESTS

def test_add_support_for_some_token(fee_burner, other_token, operator):
    
    #when: an operator adds support for some token
    fee_burner.transact({'from':operator}).addSupportFor(other_token.address, 1, 123)

    #then: this token is supported
    assert fee_burner.call().exchangeRates(other_token.address) != [0,0]


def test_add_support_for_a_token_by_a_non_operator(fee_burner, non_operator, other_token):
    
    #when: a non operator tries to add support for a token
    #then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from':non_operator}).addSupportFor(other_token.address, 1, 123)

def test_failure_when_setting_invalid_initial_rate(fee_burner, operator, other_token):

    #when: an operator tries to set invalid nominator 
    #then: an error occurs
        with pytest.raises(TransactionFailed):
            fee_burner.transact({'from':operator}).addSupportFor(other_token.address, 0, 123)

    #when: an operator tries to set invalid nominator 
    #then: an error occurs
        with pytest.raises(TransactionFailed):
            fee_burner.transact({'from':operator}).addSupportFor(other_token.address, 1, 0)



def test_failure_when_adding_already_supported_token(fee_burner, operator, other_token):
    #given: added support for some token
    fee_burner.transact({'from':operator}).addSupportFor(other_token.address, 1, 1)


    #when: the operator tries to add it one again
    #then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from' : operator}).addSupportFor(other_token.address, 1, 1)



#TODO: place to start next time
def test_exchange_omg_for_some_token(non_operator, operator, omg_token, fee_burner, other_token):
    
    # #given: added support for some token and
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)
    other_token.transact({'from': operator}).transfer(fee_burner.address, 10)


    #given: a user adds adds allowace on OMG contract and user has some initial tokens
    omg_token.transact({'from': non_operator}).approve(fee_burner.address, 10)
    user_initial_balance = other_token.call().balanceOf(non_operator)


    # TODO: 
    assert omg_token.call().allowance(non_operator, fee_burner.address) == 10
    assert user_initial_balance != 0
    
    # #when: the user sends an exchange demand OMG for other token at rate 1,1 (initial rate)
    fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 1)

    # #then: user has received token and OMGs were burnt 
    assert omg_token.call().balanceOf(DEAD_ADDRESS) == 10
    assert other_token.call().balanceOf(non_operator) == user_initial_balance + 10
    

def test_set_new_ether_exchange_rate(fee_burner, operator):

    # when: an operator changes Ether exchange rate
    fee_burner.transact({'from': operator}).setExchangeRate(ZERO_ADDRESS, 1, 1)

    # then: new exchange rate is pending
    pending_rate = fee_burner.call().pendingExchangeRates(ZERO_ADDRESS)
    assert pending_rate[-2:] == [1, 1]


def test_change_exchange_rate_by_a_non_operator(fee_burner, accounts, non_operator):

    # when: a user tries to set an new exchange rate

    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': non_operator}).setExchangeRate(
            ZERO_ADDRESS, 1, 1)

    # then: rate has not changed

    assert fee_burner.call().pendingExchangeRates(ZERO_ADDRESS) == [0, 0, 0]


def test_set_invalid_exchange_rate(fee_burner, operator):

    # when: the operator tries to set nominator to 0, expect error
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).setExchangeRate(
            ZERO_ADDRESS, 0, 1)
    # when: the operator tries to set denominator to 0, expect error
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).setExchangeRate(
            ZERO_ADDRESS, 1, 0)


def test_set_new_rate_of_an_invalid_token(fee_burner, operator, other_token):

    # when: the operator tries to set a new exchange rate to a non existent token
    # then: expect error

    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).setExchangeRate(
            other_token.address, 1, 1)


def test_setting_new_rate_while_already_pending_rate_set(fee_burner, operator):
    
    # given: pending exchange rate
    fee_burner.transact({'from': operator}).setExchangeRate(ZERO_ADDRESS, 1, 1)

    # when: the operator tires to change the rate one more
    # then: expect error
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).setExchangeRate(
            ZERO_ADDRESS, 1, 1)
