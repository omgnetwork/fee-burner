use Mix.Config

config :omisego_watcher, OmiseGOWatcher.Repo,
       adapter: Ecto.Adapters.Postgres,
       username: "omisego_dev",
       password: "omisego_dev",
       database: "omisego_dev",
       hostname: "localhost",
       pool_size: 10
