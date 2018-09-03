use Mix.Config

config :ethereumex,
       scheme: "http",
       host: "localhost",
       port: 8545,
       url: "http://localhost:8545",
       request_timeout: :infinity,
       http_options: [recv_timeout: :infinity]