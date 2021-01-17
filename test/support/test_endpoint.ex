defmodule AbsintheExtra.Support.TestEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :absinthe_extra
  use Phoenix.Router

  use Absinthe.Phoenix.Endpoint

  alias AbsintheExtra.Support.TestSchema

  scope "/", Absinthe do
    forward "/graphql", Plug, schema: TestSchema, json_code: Jason
  end
end
