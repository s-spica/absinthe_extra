defmodule Absinthe.Extra.Support.TestEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :absinthe_extra
  use Phoenix.Router

  use Absinthe.Phoenix.Endpoint

  alias Absinthe.Extra.Support.TestSchema

  scope "/", Absinthe do
    forward "/graphql", Plug, schema: TestSchema, json_code: Jason
  end
end
