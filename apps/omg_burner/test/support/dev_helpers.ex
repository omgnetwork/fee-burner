defmodule OMG.Burner.DevHelpers do

  alias ExW3.Contract
#  alias OmiseGO.API.Crypto
#  alias OmiseGO.Eth.WaitFor, as: WaitFor
#  alias OmiseGO.Eth
#
#  import OmiseGO.Eth.Encoding


  @lots_of_gas 6_721_975

  @hundred_omg trunc(:math.pow(10, 18) * 100)

  @dead_address ExW3.format_address("0xdead")
  @zero_address ExW3.format_address("0x00")

  def authority, do: ExW3.accounts|> Enum.at(0)
  def alice, do: ExW3.accounts |> Enum.at(1)
  def bob, do: ExW3.accounts |> Enum.at(2)

  def prepare_env!(root_path \\ "./") do
    {:ok, _} = Application.ensure_all_started(:ethereumex)
    {:ok, omg_address} = create_and_mint_omg(root_path, authority())
    {:ok, burner_address} = create_burner(root_path, authority(), omg_address)
    {:ok, root_chain_address, tx_hash} = create_root_chain(root_path, authority(), burner_address)

    %{
      authority_addr: authority(),
      OMG: omg_address,
      Burner: burner_address,
      RootChain: root_chain_address,
      txhash_root_chain: tx_hash
    }
  end

  def create_conf_file(%{RootChain: contract_addr, txhash_root_chain: txhash, authority_addr: authority_addr, OMG: omg_addr, Burner: burner_addr}) do
    """
    use Mix.Config
    config :omg_eth,
      contract_addr: #{inspect(contract_addr)},
      txhash_contract: #{inspect(txhash)},
      authority_addr: #{inspect(authority_addr)}
    config :omg_burner,
      burner_addr: #{inspect(burner_addr)},
      omg_addr: #{inspect(omg_addr)}
    """
  end

  def create_and_mint_omg(path_project_root, addr) do
    options = %{from: addr, gas: @lots_of_gas}

    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "OmiseGO")
    Contract.start_link(OMG, [abi: abi, bin: bytecode])

    {:ok, address, _} = Contract.deploy(OMG, options: options)

    Contract.at(OMG, address)

    formatted_addr = alice() |> ExW3.format_address
    {:ok, _} = Contract.send(OMG, :mint, [formatted_addr ,@hundred_omg], options)
    {:ok, _} = Contract.send(OMG, :finishMinting, [], options)
    {:ok, _} = Contract.send(OMG, :transferOwnership, [@dead_address], options)
    {:ok, address}

  end

  def create_burner(path_project_root, addr, omg_address) do
    options = %{from: addr, gas: @lots_of_gas}
    formatted_omg_addr = ExW3.format_address(omg_address)


    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "FeeBurner")
    Contract.start_link(Burner, [abi: abi, bin: bytecode])

    {:ok, address, _} = Contract.deploy(Burner, args: [formatted_omg_addr], options: options)
    Contract.at(Burner, address)

    {:ok, _} = Contract.send(Burner, :addSupportFor, [@zero_address, 1, 1], options)

    {:ok, address}
  end

  def create_root_chain(path_project_root, addr, burner_address) do
    options = %{from: addr, gas: @lots_of_gas}
    formatted_burner_addr = ExW3.format_address(burner_address)

    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "RootChain")
    Contract.start_link(RootChain, [abi: abi, bin: bytecode])
    {:ok, address, tx_hash} = Contract.deploy(RootChain, args: [formatted_burner_addr, 1], options: options)
    Contract.at(RootChain, address)

    {:ok, address, tx_hash}

  end

#  defp unlock_fund(account_enc) do
#    {:ok, true} = Ethereumex.HttpClient.personal_unlock_account(account_enc, "", 0)
#
#    {:ok, [eth_source_address | _]} = Ethereumex.HttpClient.eth_accounts()
#    txmap = %{from: eth_source_address, to: account_enc, value: encode_eth_rpc_unsigned_int(@ten_eth)}
#    {:ok, tx_fund} = Ethereumex.HttpClient.eth_send_transaction(txmap)
#    WaitFor.eth_receipt(tx_fund, @about_4_blocks_time)
#  end

  defp get_abi_and_bytecode!(path_project_root, contract_name) do
    %{
      "abi" => abi_list,
      "evm" => %{
        "bytecode" => %{
          "object" => bytecode
        }
      }
    } =
      path_project_root
      |> read_contracts_json!(contract_name)
      |> Poison.Parser.parse!()

    abi = ExW3.reformat_abi(abi_list)

    {abi, bytecode}

  end

  defp read_contracts_json!(path_project_root, contract_name) do
    path = "contracts/build/#{contract_name}.json"

    case File.read(Path.join(path_project_root, path)) do
      {:ok, contract_json} ->
        contract_json

      {:error, reason} ->
        raise(
          RuntimeError,
          "Can't read #{path} because #{inspect(reason)}, try running mix deps.compile plasma_contracts"
        )
    end
  end



end