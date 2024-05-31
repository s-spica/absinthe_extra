import Config

config :logger, level: :warn

config :phoenix, :json_library, Jason

config :absinthe_extra,
  endpoint: Absinthe.Extra.Support.TestEndpoint,
  path: "/graphql",
  complexity: 5,
  schema: Absinthe.Extra.Support.TestSchema

config :absinthe_extra, Absinthe.Extra.Support.TestEndpoint,
  secret_key_base: "xxxx",
  url: [http: "localhost"],
  server: false

config :absinthe_extra, joken: Absinthe.Extra.Support.TestJoken
config :joken, default_signer: "secret"
