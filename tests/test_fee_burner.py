from tests.tests_helpers import *
from tests.omg_contract_codes import OMGTOKEN_CONTRACT_ABI, OMGTOKEN_CONTRACT_BYTECODE


DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD'


def mint_token(w3, token, owner, users):
    for user in users:
        tx_hash = token.functions.mint(user, HUGE_AMOUNT).transact()
        w3.eth.waitForTransactionReceipt(tx_hash)

    w3.eth.waitForTransactionReceipt(
        token.functions.finishMinting().transact({'from': owner})
    )


@pytest.fixture()
def omg_token(w3, operator, accounts):
    # NOTE: default account is set to the operator, so it automagically deploys as if deployed by the operator
    contract_interface = {'abi': OMGTOKEN_CONTRACT_ABI, 'bin': OMGTOKEN_CONTRACT_BYTECODE}
    address = deploy_contract(w3, contract_interface)

    omg_token_contract = w3.eth.contract(
        address=address,
        abi=contract_interface['abi']
    )

    mint_token(w3, omg_token_contract, operator, accounts[0:3])

    w3.eth.waitForTransactionReceipt(
        omg_token_contract.functions.transferOwnership(DEAD_ADDRESS).transact()
    )

    return omg_token_contract


@pytest.fixture()
def other_token(w3, operator, accounts):
    compiled_erc20_token = compile_source_file('./tests/sample_erc20_contract/MintableToken.sol')
    contract_interface = compiled_erc20_token['./tests/sample_erc20_contract/MintableToken.sol:MintableToken']

    address = deploy_contract(w3, contract_interface)

    erc20_token = w3.eth.contract(
        address=address,
        abi=contract_interface['abi']
    )

    mint_token(w3, erc20_token, operator, accounts[0:3])

    w3.eth.waitForTransactionReceipt(
        erc20_token.functions.transferOwnership(DEAD_ADDRESS).transact()
    )

    return erc20_token


@pytest.fixture()
def fee_burner(w3, omg_token):
    compiled_fee_burner = compile_source_file('./contracts/FeeBurner.sol')
    contract_interface = compiled_fee_burner['./contracts/FeeBurner.sol:FeeBurner']

    address = deploy_contract(w3, contract_interface, omg_token.address)
    fee_burner_contract = w3.eth.contract(
        address=address,
        abi=contract_interface['abi']
    )

    fee_burner_contract.functions.addSupportFor(ZERO_ADDRESS, 1, 1).transact()

    return fee_burner_contract


# TESTS

def test_add_support_for_some_token(fee_burner, other_token, operator):
    # when: an operator adds support for some token
    fee_burner.functions.addSupportFor(other_token.address, 1, 123).transact()

    # then: this token is supported
    assert fee_burner.functions.exchangeRates(other_token.address).call() != [0, 0]


def test_add_support_for_a_token_by_a_non_operator(fee_burner, non_operator, other_token):
    # when: a non operator tries to add support for a token
    # then: an error occurs
    with pytest.raises(ValueError):  # TODO: now ValueError is thrown instead of TransactionFailed
        fee_burner.functions.addSupportFor(other_token.address, 1, 123).transact({'from': non_operator})


def test_failure_when_setting_invalid_initial_rate(fee_burner, operator, other_token):
    # when: an operator tries to set invalid nominator
    # then: an error occurs
    with pytest.raises(ValueError):
        fee_burner.functions.addSupportFor(other_token.address, 0, 123).transact()

    # when: an operator tries to set invalid nominator
    # then: an error occurs
    with pytest.raises(ValueError):
        fee_burner.functions.addSupportFor(other_token.address, 1, 0).transact()


def test_failure_when_adding_already_supported_token(fee_burner, operator, other_token):
    # given: added support for some token
    fee_burner.functions.addSupportFor(other_token.address, 1, 1).transact()

    # when: the operator tries to add it one again
    # then: an error occurs
    with pytest.raises(ValueError):
        fee_burner.functions.addSupportFor(other_token.address, 1, 1).transact()


def test_exchange_omg_for_some_token(non_operator, operator, omg_token, fee_burner, other_token):
    # given: added support for some token and
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)
    other_token.transact({'from': operator}).transfer(fee_burner.address, SMALL_AMOUNT)

    # given: a user adds adds allowance on OMG contract and user has some initial tokens
    omg_token.transact({'from': non_operator}).approve(fee_burner.address, SMALL_AMOUNT)
    user_initial_balance = other_token.call().balanceOf(non_operator)

    # when: the user sends an exchange demand OMG for other token at rate 1,1 (initial rate)
    fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 1)

    # then: user has received token and OMGs have been burnt
    assert omg_token.call().balanceOf(DEAD_ADDRESS) == 1
    assert other_token.call().balanceOf(non_operator) == user_initial_balance + 1


def test_exchange_at_invalid_rate(non_operator, omg_token, fee_burner, other_token):
    # given: added support for some token and
    fee_burner.transact().addSupportFor(other_token.address, 1, 1)
    other_token.transact().transfer(fee_burner.address, SMALL_AMOUNT)

    # given: a user adds adds allowance on OMG contract and user has some initial tokens
    omg_token.transact({'from': non_operator}).approve(fee_burner.address, SMALL_AMOUNT)
    user_initial_balance = other_token.call().balanceOf(non_operator)

    # when: the user sends an exchange demand OMG for other token at rate 2,1 (not current rate)
    # then: error
    with pytest.raises(ValueError):
        fee_burner.transact({'from': non_operator}).exchange(other_token.address, 2, 1, 1, 1)

    # when: the user sends an exchange demand OMG for other token at valid rate, but amounts aren't at this rate
    # then: error
    with pytest.raises(ValueError):
        fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 2)

    # TODO: probably I needn't check this
    assert omg_token.functions.balanceOf(DEAD_ADDRESS).call() == 0
    assert other_token.functions.balanceOf(non_operator).call() == user_initial_balance


def test_exchange_when_user_has_not_allowed_transfer(non_operator, omg_token, fee_burner, other_token):
    # given: added support for some token
    fee_burner.functions.addSupportFor(other_token.address, 1, 1).transact()
    other_token.functions.transfer(fee_burner.address, SMALL_AMOUNT).transact()

    # when: user sends an exchange demand not having allowed for the transfer
    # then: error
    with pytest.raises(ValueError):
        fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 1)

    assert omg_token.functions.balanceOf(DEAD_ADDRESS).call() == 0
    assert other_token.functions.balanceOf(fee_burner.address).call() == SMALL_AMOUNT


def test_exchange_when_user_does_not_have_funds(accounts, omg_token, fee_burner, other_token):

    user = accounts[5]

    # given: added support for some token and
    fee_burner.functions.addSupportFor(other_token.address, 1, 1).transact()
    other_token.functions.transfer(fee_burner.address, SMALL_AMOUNT).transact()

    # given: a user adds adds allowance on OMG contract
    omg_token.transact({'from': user}).approve(fee_burner.address, SMALL_AMOUNT)

    # when: user sends an exchange demand not having allowed for the transfer
    # then: error
    with pytest.raises(ValueError):
        fee_burner.transact({'from': user}).exchange(other_token.address, 1, 1, 1, 1)

    assert omg_token.functions.balanceOf(DEAD_ADDRESS).call() == 0
    assert other_token.functions.balanceOf(fee_burner.address).call() == SMALL_AMOUNT


def test_exchange_when_fee_burner_does_not_have_funds(operator, non_operator, omg_token, fee_burner, other_token):
    # given: added support for some token and
    fee_burner.transact({'from': operator}).addSupportFor(other_token.address, 1, 1)

    # given: a user adds adds allowance on OMG contract and user has some initial tokens
    omg_token.transact({'from': non_operator}).approve(fee_burner.address, SMALL_AMOUNT)
    user_initial_balance = other_token.call().balanceOf(non_operator)

    # when: the user sends an exchange demand OMG for other token at rate 1,1 (initial rate),
    # then: error
    with pytest.raises(ValueError):
        fee_burner.transact({'from': non_operator}).exchange(other_token.address, 1, 1, 1, 1)

    assert other_token.call().balanceOf(non_operator) == user_initial_balance


def test_set_new_ether_exchange_rate(fee_burner):
    # when: an operator changes Ether exchange rate
    fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 1, 1).transact()

    # then: new exchange rate is pending
    pending_rate = fee_burner.functions.pendingExchangeRates(ZERO_ADDRESS).call()
    assert pending_rate[-2:] == [1, 1]


def test_change_exchange_rate_by_a_non_operator(fee_burner, accounts, non_operator):
    # when: a user tries to set an new exchange rate
    with pytest.raises(ValueError):
        fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 1, 1).transact({'from': non_operator})

    # then: rate has not changed

    assert fee_burner.functions.pendingExchangeRates(ZERO_ADDRESS).call() == [0, 0, 0]


def test_set_invalid_exchange_rate(fee_burner, operator):

    # when: the operator tries to set nominator to 0, expect error
    with pytest.raises(ValueError):
        fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 0, 1).transact()
    # when: the operator tries to set denominator to 0, expect error
    with pytest.raises(ValueError):
        fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 1, 0).transact()


def test_set_new_rate_of_an_invalid_token(fee_burner, operator, other_token):
    # when: the operator tries to set a new exchange rate to a non existent token
    # then: expect error
    with pytest.raises(ValueError):
        fee_burner.functions.setExchangeRate(other_token.address, 1, 1).transact()


def test_setting_new_rate_while_already_pending_rate_set(fee_burner, operator):
    # given: pending exchange rate
    fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 1, 1).transact()

    # when: the operator tires to change the rate one more
    # then: expect error
    with pytest.raises(ValueError):
        fee_burner.functions.setExchangeRate(ZERO_ADDRESS, 1, 1).transact()
