defmodule AbsintheExtra.CaseTest do
  use ExUnit.Case, async: true

  import AbsintheExtra.Case.Assertion
  import AbsintheExtra.Case.QueryBuilder
  import Phoenix.ConnTest

  alias AbsintheExtra.Support.TestEndpoint
  alias AbsintheExtra.Support.TestSchema

  setup do
    opts = [strategy: :one_for_one, name: AbsintheExtra.Supervisor]
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
      fields = fields(:interface_user, complexity: 2, schema: TestSchema)

      query = graphql_query(:interface_user, fields)

      assert "{interface_user {... on InterfaceConcreteUser  " <>
               "{name, user {... on InterfaceConcreteUser  " <>
               "{name, user {... on InterfaceConcreteUser  " <>
               "{name}}}}}}}" == query

      assert %{name: "name", user: %{name: "name", user: %{name: "name"}}} ==
               graphql_success(conn, query)
    end

    test "query: argument_field_user. ensure child is passed", %{conn: conn} do
      fields = fields(:argument_field_user)
      fields = argument_fields(fields, name: [child: true])
      query = graphql_query(:argument_field_user, [parent: true], fields)

      assert "{argument_field_user(parent: true) {name(child: true)}}" == query
      assert %{name: "name"} == graphql_success(conn, query)
    end
  end

  describe "unpaginate_fields/1" do
    test "extract nodes" do
      assert [%{id: 1}] == unpaginate_fields(%{edges: [%{node: %{id: 1}}]})
    end
  end

  describe "drop_fields/2" do
    test "drop nested fields" do
      assert [_on: [interface_concrete_user: [:name]]] ==
               fields(:interface_user, complexity: 2, schema: TestSchema)
               |> drop_fields([:user])
    end
  end
end
