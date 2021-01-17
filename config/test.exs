import Config

config :logger, level: :warn

config :phoenix, :json_library, Jason

config :absinthe_extra,
  endpoint: AbsintheExtra.Support.TestEndpoint,
  path: "/graphql",
  complexity: 5,
  schema: AbsintheExtra.Support.TestSchema

config :absinthe_extra, AbsintheExtra.Support.TestEndpoint,
  secret_key_base: "xxxx",
  url: [http: "localhost"],
  server: false
