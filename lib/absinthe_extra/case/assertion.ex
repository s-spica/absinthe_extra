defmodule AbsintheExtra.Case.Assertion do
  @moduledoc false

  use ExUnit.CaseTemplate

  import Phoenix.ConnTest

  @path Application.compile_env(:absinthe_extra, :path)
  @endpoint Application.compile_env(:absinthe_extra, :endpoint)

  @spec graphql_error(Plug.Conn.t(), query :: String.t()) :: map
  def graphql_error(conn, query, opts \\ []) do
    conn = run_query(conn, query, opts)
    response = json_response(conn, 200)

    assert response["data"] == nil
    response["errors"]
  end

  @spec graphql_success(Plug.Conn.t(), query :: String.t()) :: map
  def graphql_success(conn, query, opts \\ []) do
    conn = run_query(conn, query, opts)
    response = json_response(conn, 200)

    assert response["errors"] == nil
    # support only one query
    response["data"] |> Enum.at(0) |> (fn {_, v} -> v end).() |> key_to_atom()
  end

  def graphql_node_success(conn, query) do
    data = graphql_success(conn, query)

    edges_data(data)
  end

  def edges_data(edges), do: edges |> Map.get(:edges) |> Enum.map(& &1.node)

  defp run_query(conn, query, opts) do
    path = Keyword.get(opts, :path, @path)

    post(conn, path, %{"query" => query})
  end

  defp key_to_atom(values) when is_list(values),
    do: Enum.map(values, &key_to_atom/1)

  defp key_to_atom(values) when is_map(values) do
    values |> Enum.map(&key_to_atom/1) |> Enum.into(%{})
  end

  defp key_to_atom({key, value}) when is_map(value) or is_list(value) do
    key = String.to_existing_atom(key)
    value = key_to_atom(value)
    {key, value}
  end

  defp key_to_atom({key, value}) do
    key = String.to_existing_atom(key)
    {key, value}
  end

  defp key_to_atom(field), do: field
end
