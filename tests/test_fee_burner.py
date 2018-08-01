import json

from ethereum.tools.tester import TransactionFailed

from .tests_helpers import *
from .omg_contract_codes import OMGTOKEN_CONTRACT_ABI, OMGTOKEN_CONTRACT_BYTECODE

DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD'


def mint_token(chain, token, accounts, owner):
    used_accounts = accounts[0:2]

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
                                                              'from': owner
                                                          },
                                                          deploy_args=[omg_address]
                                                          )
    return fee_burner


def deploy_sample_erc20_contract(chain, owner):
    erc20_token, _ = chain.provider.get_or_deploy_contract(
        'MintableToken',
        deploy_transaction={'from': owner}
    )
    return erc20_token



@pytest.fixture()
def OMGContractClass(w3):
    return w3.eth.contract(
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
def other_token(chain, accounts, operator):
    owner = accounts[0]

    token = deploy_sample_erc20_contract(chain, owner)

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
    # when: an operator adds support for some token
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 123)

    # then: this token is supported
    assert fee_burner.call().exchangeRates(other_token.address) != [0, 0]


def test_add_support_for_a_token_by_a_non_operator(fee_burner, non_operator, other_token):
    # when: a non operator tries to add support for a token
    # then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': non_operator}).addSupportFor(other_token.address, 1, 123)


def test_failure_when_setting_invalid_initial_rate(fee_burner, operator, other_token):
    # when: an operator tries to set invalid nominator
    # then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 0, 123)

    # when: an operator tries to set invalid nominator
    # then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 0)


def test_failure_when_adding_already_supported_token(fee_burner, operator, other_token):
    # given: added support for some token
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)

    # when: the operator tries to add it one again
    # then: an error occurs
    with pytest.raises(TransactionFailed):
        fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)


# TODO
def test_exchange_omg_for_some_token(non_operator, operator, omg_token, fee_burner, other_token):
    # given: added support for some token and
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)
    other_token.transact({'from': operator}).transfer(fee_burner.address, SMALL_AMOUNT)

    # given: a user adds adds allowace on OMG contract and user has some initial tokens
    omg_token.transact({'from': non_operator}).approve(fee_burner.address, SMALL_AMOUNT)
    user_initial_balance = other_token.call().balanceOf(non_operator)

    # when: the user sends an exchange demand OMG for other token at rate 1,1 (initial rate)
    fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 1)

    # then: user has received token and OMGs have been burnt
    assert omg_token.call().balanceOf(DEAD_ADDRESS) == 1
    # assert other_token.call().balanceOf(non_operator) == user_initial_balance + 1


# TODO: remove
def test_playground(non_operator, operator, fee_burner, omg_token, other_token):
    # get intial balances
    nonOperatorTokenBalance = other_token.call().balanceOf(non_operator)
    operatorTokenBalance = other_token.call().balanceOf(operator)

    nonOperatorOMGBalance = omg_token.call().balanceOf(non_operator)
    operatorOMGBalance = omg_token.call().balanceOf(operator)

    # check whether other token works properly

    # transfer from
    other_token.transact({'from': operator}).approve(non_operator, 10 * SMALL_AMOUNT)
    other_token.transact({'from': non_operator}).transferFrom(operator, DEAD_ADDRESS, SMALL_AMOUNT)

    assert other_token.call().balanceOf(operator) == operatorTokenBalance - SMALL_AMOUNT
    assert other_token.call().balanceOf(DEAD_ADDRESS) == SMALL_AMOUNT

    # transfer 
    other_token.transact({'from': non_operator}).transfer(operator, SMALL_AMOUNT)

    assert other_token.call().balanceOf(operator) == operatorTokenBalance
    assert other_token.call().balanceOf(non_operator) == nonOperatorTokenBalance - SMALL_AMOUNT

    # check whether omg token works properly

    # transfer from
    omg_token.transact({'from': operator}).approve(non_operator, 10 * SMALL_AMOUNT)
    omg_token.transact({'from': non_operator}).transferFrom(operator, DEAD_ADDRESS, SMALL_AMOUNT)

    assert omg_token.call().balanceOf(operator) == operatorOMGBalance - SMALL_AMOUNT
    assert omg_token.call().balanceOf(DEAD_ADDRESS) == SMALL_AMOUNT

    # transfer 
    omg_token.transact({'from': non_operator}).transfer(operator, SMALL_AMOUNT)

    assert omg_token.call().balanceOf(operator) == operatorOMGBalance
    assert omg_token.call().balanceOf(non_operator) == nonOperatorOMGBalance - SMALL_AMOUNT

    # FEE BURNER

    omg_token.transact({'from': non_operator}).approve(fee_burner.address, 10 * SMALL_AMOUNT)
    omg_token.transact({'from': operator}).transfer(fee_burner.address, 10 * SMALL_AMOUNT)
    other_token.transact({'from': operator}).transfer(fee_burner.address, 10 * SMALL_AMOUNT)

    # 1
    # fee_burner.transact({'from': non_operator}).foo(ZERO_ADDRESS)
    # assert omg_token.call().balanceOf(DEAD_ADDRESS) == 20

    # 2
    # fee_burner.transact({'from': non_operator}).foo(omg_token.address)
    # assert omg_token.call().balanceOf(DEAD_ADDRESS) == 20

    # 3
    # fee_burner.transact({'from': non_operator}).foo(other_token.address)
    # assert other_token.call().balanceOf(DEAD_ADDRESS) == 20

    # 4 
    # fee_burner.transact({'from': non_operator}).foo(other_token.address)
    # assert omg_token.call().allowance(fee_burner.address, DEAD_ADDRESS) == 1000

    # 5 
    fee_burner.transact({'from': non_operator}).foo(other_token.address)
    assert other_token.call().allowance(fee_burner.address, DEAD_ADDRESS) == 1000

    # 6 
    # fee_burner.transact({'from': non_operator}).foo(omg_token.address)
    # assert omg_token.call().allowance(fee_burner.address, DEAD_ADDRESS) == 1000
    # assert omg_token.call().balanceOf(DEAD_ADDRESS) == 21


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
