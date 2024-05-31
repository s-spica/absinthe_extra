defmodule Absinthe.Extra.Support.TestEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :absinthe_extra
  use Phoenix.Router

  use Absinthe.Phoenix.Endpoint

  alias Absinthe.Extra.Support.TestSchema

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

  scope "/", Absinthe do
    forward "/graphql", Plug, schema: TestSchema, json_code: Jason
  end
end
