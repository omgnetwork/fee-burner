ExUnitFixtures.start()
ExUnitFixtures.load_fixture_files("./fixtures.exs")
ExUnit.configure(exclude: [integration: true])
ExUnit.start()
