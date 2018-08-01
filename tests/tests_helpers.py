import pytest
from solc import compile_files
from web3.auto import w3 as _w3


HUGE_AMOUNT = 10**36
MEDIUM_AMOUNT = 10000
SMALL_AMOUNT = 10
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'


@pytest.fixture()
def w3():

    try:
        _w3.isConnected()
    except TypeError as error:
        raise EnvironmentError('Could not connect to any Ethereum client.')

    _w3.eth.defaultAccount = _w3.eth.accounts[0]
    return _w3


@pytest.fixture()
def accounts(w3):
    return w3.eth.accounts


@pytest.fixture()
def operator(accounts):
    return accounts[0]


@pytest.fixture()
def non_operator(operator, accounts):
    for user in accounts:
        if user != operator:
            return user


def compile_source_file(file_path):
    return compile_files([file_path])


def deploy_contract(w3, contract_interface, deploy_args=None):

    contract = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )

    tx_hash = contract.constructor(deploy_args).transact()
    w3.eth.waitForTransactionReceipt(tx_hash)

    address = w3.eth.getTransactionReceipt(tx_hash)['contractAddress']

    return address
