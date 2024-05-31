defmodule Absinthe.Extra.RelaySignedQueryTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  alias Absinthe.Extra.Support.TestEndpoint
  alias Absinthe.Extra.Support.TestJoken

  @endpoint Application.compile_env(:absinthe_extra, :endpoint)

  setup do
    opts = [strategy: :one_for_one, name: Absinthe.Extra.Supervisor]
    Supervisor.start_link([TestEndpoint], opts)

    %{conn: build_conn()}
  end

  describe "persisting" do
    test "can generate signed id", %{conn: conn} do
      query = "{__schema{__typename}}"

      assert %{resp_body: body} =
               post(conn, "/relay/persisting", %{"text" => query})

      assert {:ok, %{"id" => doc_id}} = Jason.decode(body)
      assert {:ok, %{"query" => ^query}} = TestJoken.verify_and_validate(doc_id)
    end
  end

  describe "graphql" do
    test "should run signed query", %{conn: conn} do
      doc_id = TestJoken.generate_and_sign!(%{query: "{__schema{__typename}}"})

      assert %{
               resp_body: ~S({"data":{"__schema":{"__typename":"__Schema"}}})
             } =
               post(conn, "/relay/graphql", %{"doc_id" => doc_id})
    end
  end
end
