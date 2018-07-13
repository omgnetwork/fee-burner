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
    for validator in accounts:
        chain.wait.for_receipt(
            token.transact({'from': owner}).mint(validator, HUGE_AMOUNT)
        )
    chain.wait.for_receipt(
        token.transact({'from': owner}).finishMinting()
    )


def deploy_fee_burner(omg_address, chain, owner, etherNominator, etherDenominator):
    fee_burner, _ = chain.provider.get_or_deploy_contract('FeeBurner',
                                                          deploy_transaction={
                                                              'from': owner},
                                                          deploy_args=[
                                                              omg_address, etherNominator, etherDenominator]
                                                          )
    return fee_burner


@pytest.fixture()
def operator(accounts):
    return accounts[0]


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
    return deploy_fee_burner(omg_token.address, chain, operator, 1, 1)

# TESTS


def test_contracts_deployment(omg_token, other_token, fee_burner, operator):

    assert omg_token.call().name() == "OMGToken"
    assert omg_token.call().symbol() == "OMG"

    assert omg_token.address != other_token.address

    assert omg_token.call().owner() == DEAD_ADDRESS
    assert other_token.call().owner() == DEAD_ADDRESS


def test_fee_burner_construction(chain, omg_token, operator):

    # when: an operator deploys a fee burner contract
    fee_burner = deploy_fee_burner(omg_token.address, chain, operator, 1, 10)

    # then: its operator is set to the given operator
    assert fee_burner.call().operator() == operator

    # then: OMG token reference is set properly
    assert fee_burner.call().OMGToken().lower() == omg_token.address

    # then: Ether exchange rate is set as in given params
    assert fee_burner.call().exchangeRates(ZERO_ADDRESS) == [1, 10]

    # then: Ether pending exchange rate is not set
    assert fee_burner.call().pendingExchangeRates(ZERO_ADDRESS) == [0, 0, 0]


def test_set_new_ether_exchange_rate(fee_burner, operator):

    # when: an operator changes Ether exchange rate
    fee_burner.transact({'from': operator}).setExchangeRate(ZERO_ADDRESS, 1, 1)

    # then: new exchange rate is pending
    pending_rate = fee_burner.call().pendingExchangeRates(ZERO_ADDRESS)
    assert pending_rate[-2:] == [1, 1]


def test_change_exchange_rate_by_a_non_operator(fee_burner, accounts, operator):

    # given: a non operator
    for user in accounts:
        if user != operator:
            break

    # when: a user tries to set an new exchange rate

    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': user}).setExchangeRate(
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
