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
defmodule OmiseGo.BurnerCore.DevHelpers do
  @moduledoc """
  Helpers used when setting up development environment and test fixtures, related to contracts and ethereum.
  Run against `geth --dev` and similar.
  """

  alias OmiseGO.API.Crypto
  alias OmiseGO.Eth.WaitFor, as: WaitFor
  import OmiseGO.Eth.Encoding
  alias OmiseGO.Eth

  # safe, reasonable amount, equal to the testnet block gas limit
  @lots_of_gas 4_712_388

  # about 4 Ethereum blocks on "realistic" networks, use to timeout synchronous operations in demos on testnets
  @about_4_blocks_time 60_000

  @one_hundred_eth trunc(:math.pow(10, 18) * 100)

  def prepare_env!(root_path \\ "./") do
    {:ok, _} = Application.ensure_all_started(:ethereumex)
    {:ok, authority} = OmiseGO.Eth.DevHelpers.create_and_fund_authority_addr
    {:ok, }

  end

  def create_new_omg_token(path_project_root, addr) do
  end


end