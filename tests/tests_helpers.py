import pytest
import os
from solc import compile_files
from web3.auto import w3 as _w3
from eth_tester.exceptions import TransactionFailed

HUGE_AMOUNT = 10 ** 36
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


@pytest.fixture()
def provider(w3):
    for provider in w3.providers:
        if provider.isConnected:
            return provider
    raise EnvironmentError("Could not find any connected provider.")


class RaisesTransactionFailed:
    # see https://github.com/pipermerriam/web3.py/issues/75
    def __enter__(self):
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        with pytest.raises(TransactionFailed):
            if exception_type == ValueError \
                    and exception_value.args[0]['message'] == u"VM Exception while processing transaction: revert":

                raise TransactionFailed

        return True


def increase_time(provider, time):
    result = provider.make_request("evm_increaseTime", [time])
    return result['result']


def mine_blocks(provider, blocks_number):
    for _ in range(blocks_number):
        provider.make_request('evm_mine', [])


def compile_source_file(file_path):
    current_directory = os.path.dirname(__file__)
    project_root = os.path.join(current_directory, '..')
    project_root = os.path.normpath(project_root)

    return compile_files([file_path], allow_paths=project_root)


def deploy_contract(w3, contract_interface, deploy_args=None):
    contract = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )

    tx_hash = contract.constructor(deploy_args).transact()
    w3.eth.waitForTransactionReceipt(tx_hash)

    address = w3.eth.getTransactionReceipt(tx_hash)['contractAddress']

    return address
