defmodule Absinthe.Extra.Controller.RelaySignedQueryController do
  @moduledoc """
  This controller is used to generate persist query ids for relay.

  ## Usage

  in `config.ex`, add encoder(signer) module

  ```elixir
  config :absinthe_extra, joken: YourJoken
  ```

  in `router.ex`, mount this controller

  ```elixir

  # make sure not to use this in production
  unless Mix.env() == :prod do
    scope "/relay" do
      post "/persisting", RelaySignedQueryController, :persisting
    end
  end
  ```

  then run `relay-compiler` with persisted query option `--repersist`.
  also do not forget to target persistConfig url in relay.config.js to the phoenix server.

  ```js
  persistConfig: {
    url: "http://localhost:4000/relay/persisting",
  }
  ```
  """
  use Phoenix.Controller

  import Plug.Conn

  def persisting(conn, %{"text" => text}) do
    joken = Application.fetch_env!(:absinthe_extra, :joken)
    id = joken.generate_and_sign!(%{query: text})
    json(conn, %{id: id})
  end
end
