# AbsintheExtra

[![Hex](https://img.shields.io/hexpm/v/absinthe_extra)](https://hex.pm/packages/absinthe_extra)

`AbsintheExtra` is a extra tool for absinthe

- query builder
- policy middleware

## Installation

```elixir
def deps do
  [
    {:absinthe_extra, "~> 0.1.0"}
  ]
end
```

```elixir
config :absinthe_extra,
  endpoint: Web.Endpoint,
  path: "/graphql",
  complexity: 5,
  schema: Web.Schema
```

these fields also can be passed through options

## QueryBuilder/Assertion Example

### Schema for test

```elixir
defmodule Web.Schema do
  use Absinthe.Schema

  query do
    field :user, :user do
      arg :id, :id
    end
  end

  object :user do
    field :name, :string do
      arg :capitalize, :boolean
    end
  end
end
```

### How to use

```elixir
iex(1) > fields = fields(:user)
iex(2) > fields = argument_fields(fields, name: [capitalize: false])
iex(3) > query = graphql_query(:user, [id: 1], fields)
iex(4) > assert %{name: "name"} == graphql_success(conn, query)
```

## Phase Introspection

this phase is to block introspection

### How to use

```elixir
    forward "/graphql", Absinthe.Plug,
      schema: Schema,
      pipeline: {Phase.Introspection, :pipeline}
```

## Relay Signed Query

Relay provides [persisted query](https://relay.dev/docs/guides/persisted-queries/) out of the box but maintaining static query ID can be a pain.
This provides dynamic persisted query called signed query which is JWT instead of hashed string so it can be decoded on demand.

### How to use

```elixir
    scope "/relay" do
      post "/persisting",
          Absinthe.Extra.Controller.RelaySignedQueryController,
          :persisting

      post "/graphql",
          Absinthe.Plug,
          schema: TestSchema,
          json_code: Jason,
          document_providers:
            Absinthe.Extra.Plug.RelaySignedQueryDocumentProvider
    end
```
