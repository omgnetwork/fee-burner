# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#TODO: move it somewhere
defmodule OMG.BurnerCore.DevHelpers do
  @moduledoc """
  Helpers used when setting up development environment and test fixtures, related to contracts and ethereum.
  Run against `geth --dev` and similar.
  """
  alias OmiseGO.API.Crypto
  alias OmiseGO.Eth.WaitFor, as: WaitFor
  import OmiseGO.Eth.Encoding
  alias OmiseGO.Eth
  import OmiseGO.Eth.Encoding

  # safe, reasonable amount, equal to the testnet block gas limit
  @lots_of_gas 6_721_975

  # about 4 Ethereum blocks on "realistic" networks, use to timeout synchronous operations in demos on testnets
  @about_4_blocks_time 60_000

  @ten_eth trunc(:math.pow(10, 18) * 10)
  @hundred_omg trunc(:math.pow(10, 18) * 100)

  @dead_address ExW3.format_address("0xdead")
  @zero_address ExW3.format_address("0x00")

  def alice do
    ExW3.accounts()
    |> Enum.at(1)
  end


  def formatted_alice do
    alice
    |> ExW3.format_address
  end

  def bob do
    ExW3.accounts()
    |> Enum.at(2)
  end

  def prepare_env!(root_path \\ "./") do
    {:ok, _} = Application.ensure_all_started(:ethereumex)
    {:ok, authority} = create_and_fund_authority_addr()
    {:ok, omg_address} = create_and_mint_omg(root_path, owner)
    {:ok, burner_address} = create_burner(root_path, authority, omg_address)
    {:ok, contract_addr} = create_root_chain(root_path, authority, burner_address)

    {
      :ok,
      %{
        authority: authority,
        OMG: omg_address,
        Burner: burner_address,
        RootChain: contract_addr
      }
    }
  end


  def owner() do
    ExW3.accounts
    |> Enum.at(0)
  end

  def create_and_fund_authority_addr do
    {:ok, authority} = Ethereumex.HttpClient.personal_new_account("")
    {:ok, _} = unlock_fund(authority)

    {:ok, authority}
  end

  defp unlock_fund(account_enc) do
    {:ok, true} = Ethereumex.HttpClient.personal_unlock_account(account_enc, "", 0)
    {:ok, [eth_source_address | _]} = Ethereumex.HttpClient.eth_accounts()
    txmap = %{from: eth_source_address, to: account_enc, value: encode_eth_rpc_unsigned_int(@ten_eth)}
    {:ok, tx_fund} = Ethereumex.HttpClient.eth_send_transaction(txmap)
    WaitFor.eth_receipt(tx_fund, @about_4_blocks_time)
  end

  def create_and_mint_omg(path_project_root, addr) do
    options = %{from: addr, gas: @lots_of_gas}

    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "OmiseGO")
    ExW3.Contract.start_link(OMG, [abi: abi, bin: bytecode])

    {:ok, address} = ExW3.Contract.deploy(OMG, options: options)

    ExW3.Contract.at(OMG, address)

    {:ok, _} = ExW3.Contract.send(OMG, :mint, [formatted_alice(), @hundred_omg], options)
    {:ok, _} = ExW3.Contract.send(OMG, :finishMinting, [], options)
    {:ok, _} = ExW3.Contract.send(OMG, :transferOwnership, [@dead_address], options)
    {:ok, address}
  end

  defp create_burner(path_project_root, addr, omg_address) do
    options = %{from: addr, gas: @lots_of_gas}
    formatted_omg_addr = ExW3.format_address(omg_address)


    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "FeeBurner")
    ExW3.Contract.start_link(Burner, [abi: abi, bin: bytecode])

    {:ok, address} = ExW3.Contract.deploy(Burner, args: [formatted_omg_addr], options: options)
    ExW3.Contract.at(Burner, address)

    {:ok, _} = ExW3.Contract.send(Burner, :addSupportFor, [@zero_address, 1, 1], options)

    {:ok, address}
  end


  defp create_root_chain(path_project_root, addr, burner_address) do
    options = %{from: addr, gas: @lots_of_gas}
    formatted_burner_addr = ExW3.format_address(burner_address)

    {abi, bytecode} = get_abi_and_bytecode!(path_project_root, "RootChain")
    ExW3.Contract.start_link(RootChain, [abi: abi, bin: bytecode])
    {:ok, address} = ExW3.Contract.deploy(RootChain, args: [formatted_burner_addr], options: options)
    ExW3.Contract.at(RootChain, address)

    {:ok, address}

  end

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