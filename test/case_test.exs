defmodule Absinthe.Extra.CaseTest do
  use ExUnit.Case, async: true

  import Absinthe.Extra.Case.Assertion
  import Absinthe.Extra.Case.QueryBuilder
  import Phoenix.ConnTest

  alias Absinthe.Extra.Support.TestEndpoint
  alias Absinthe.Extra.Support.TestSchema

  setup do
    opts = [strategy: :one_for_one, name: Absinthe.Extra.Supervisor]
    Supervisor.start_link([TestEndpoint], opts)

    %{conn: build_conn()}
  end

  describe "query_success/2" do
    test "query: node", %{conn: conn} do
      fields = fields(:user)
      global_id = Absinthe.Relay.Node.to_global_id(:user, "id", TestSchema)
      query = graphql_node_query(:user, "id", fields)

      assert "{node(id: \"#{global_id}\") {... on User  {age, id, name}}}" ==
               query

      assert %{
               name: "name",
               age: "ONE",
               id: global_id
             } ==
               graphql_success(conn, query)
    end

    test "query: user", %{conn: conn} do
      fields = fields(:user)
      id = Absinthe.Relay.Node.to_global_id(:user, "id", TestSchema)
      query = graphql_query(:user, fields)

      assert "{user {age, id, name}}" == query
      assert %{name: "name", age: "ONE", id: id} == graphql_success(conn, query)
    end

    test "query: interface_user", %{conn: conn} do
      fields = fields(:interface_user, complexity: 4, schema: TestSchema)

      query = graphql_query(:interface_user, fields)

      assert "{interface_user {... on InterfaceConcreteUser  " <>
               "{name, user {... on InterfaceConcreteUser  " <>
               "{name}}}}}" == query

      assert %{name: "name", user: %{name: "name"}} ==
               graphql_success(conn, query)
    end

    test "query: argument_user. ensure child is passed", %{conn: conn} do
      fields = fields(:argument_user, complexity: 1)
      fields = argument_fields(fields, name: [child: true])

      query = graphql_query(:argument_user, [parent: true], fields)

      assert "{argument_user(parent: true) {name(child: true)}}" == query
      assert %{name: "name"} == graphql_success(conn, query)
    end
  end

  describe "unpaginate_fields/1" do
    test "extract nodes" do
      assert [%{id: 1}] == unpaginate_fields(%{edges: [%{node: %{id: 1}}]})
    end
  end

  describe "drop_invalid_query_fields/1" do
    test "query: argument_user. drop unset fields" do
      fields =
        fields(:argument_user, complexity: 2)
        |> drop_invalid_query_fields()

      query = graphql_query(:argument_user, [parent: true], fields)

      assert "{argument_user(parent: true)}" == query
    end
  end

  describe "drop_fields/2" do
    test "drop nested fields" do
      assert [_on: [interface_concrete_user: [:name]]] ==
               fields(:interface_user, complexity: 2, schema: TestSchema)
    end

    test "drop query fields" do
      assert [] ==
               fields(:argument_user, complexity: 1, schema: TestSchema)
               |> argument_fields(name: [child: true])
               |> drop_fields([:name])
    end
  end
end
