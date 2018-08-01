from tests.tests_helpers import *

from tests.omg_contract_codes import OMGTOKEN_CONTRACT_ABI, OMGTOKEN_CONTRACT_BYTECODE


@pytest.fixture()
def omg_token(w3):
    # NOTE: default account is set to the operator, so it automagically deploys as if deployed by the operator
    contract_interface = {'abi': OMGTOKEN_CONTRACT_ABI, 'bin': OMGTOKEN_CONTRACT_BYTECODE}
    address = deploy_contract(w3, contract_interface)

    omg_token_contract = w3.eth.contract(
        address=address,
        abi=contract_interface['abi']
    )
    return omg_token_contract


@pytest.fixture()
def fee_burner(w3, omg_token):
    compiled_fee_burner = compile_source_file('./contracts/FeeBurner.sol')
    contract_interface = compiled_fee_burner['./contracts/FeeBurner.sol:FeeBurner']

    address = deploy_contract(w3, contract_interface, omg_token.address)
    fee_burner_contract = w3.eth.contract(
        address=address,
        abi=contract_interface['abi']
    )

    return fee_burner_contract


def test_deploy_omg_contract(omg_token, fee_burner, operator):

    assert omg_token.functions.name().call() == "OMGToken"
    assert fee_burner.functions.balance().call() == 0

    assert fee_burner.functions.operator().call() == operator
    assert fee_burner.functions.OMGToken().call() == omg_token.address

