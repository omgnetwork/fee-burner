def test_project(project):
    assert project.project_dir == "/home/imapp/Developer/fee-burner/populus"
    assert 'Greeter' in project.compiled_contract_data


def test_greeter(chain):
    greeter, _ = chain.provider.get_or_deploy_contract('Greeter')
    assert greeter.call().greet() == 'Hello'


def test_custom_greeting(chain):
    greeter, _ = chain.provider.get_or_deploy_contract('Greeter')

    set_txn_hash = greeter.transact().setGreeting('Guten Tag')
    chain.wait.for_receipt(set_txn_hash)

    greeting = greeter.call().greet()
    assert greeting == 'Guten Tag'


def test_named_greeting(chain):
    greeter, _ = chain.provider.get_or_deploy_contract('Greeter')

    set_txn_hash = greeter.transact().setGreeting('Hello')
    chain.wait.for_receipt(set_txn_hash)

    greeting = greeter.call().greet('John')
    assert greeting == 'Hello John'
    
    greeting = greeter.call().greet('William')
    assert greeting == 'Hello William'
