defmodule Absinthe.Extra.PhaseTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule TestSchema do
    use Absinthe.Schema

    query do
    end
  end

  describe "introspection" do
    test "deny" do
      query = "{__schema{__typename}}"

      opts =
        Absinthe.Plug.init(
          schema: TestSchema,
          pipeline: {Absinthe.Extra.Phase.Introspection, :pipeline}
        )

      assert %{status: 200, resp_body: body} =
               conn(:post, "/", %{"query" => query})
               |> put_req_header("content-type", "application/graphql")
               |> plug_parser
               |> Absinthe.Plug.call(opts)

      assert %{
               "errors" => [%{"message" => "unauthorized"}]
             } = Jason.decode!(body)
    end
  end

  def plug_parser(conn) do
    opts =
      Plug.Parsers.init(
        parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
        json_decoder: Jason
      )

    Plug.Parsers.call(conn, opts)
  end
end
