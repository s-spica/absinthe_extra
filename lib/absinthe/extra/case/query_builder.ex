defmodule Absinthe.Extra.Case.QueryBuilder do
  @moduledoc false

  alias Absinthe.Type

  import Absinthe.Extra.Helper

  require Absinthe.Extra.Helper

  @schema Application.compile_env(:absinthe_extra, :schema)
  @complexity Application.compile_env(:absinthe_extra, :complexity)

  defmodule Query do
    defstruct [:identifier, :non_null_args]

    def new(identifier, %{args: args}) when is_atom(identifier) do
      args
      |> Enum.reduce(%__MODULE__{identifier: identifier, non_null_args: []}, fn
        {identifier,
         %Type.Argument{identifier: _, type: %Absinthe.Type.NonNull{}}},
        acc ->
          {_, acc} =
            acc
            |> Map.get_and_update!(:non_null_args, fn args ->
              {args, [identifier | args]}
            end)

          acc

        {_, _}, acc ->
          acc
      end)
    end

    def new(identifier, _) when is_atom(identifier),
      do: %__MODULE__{identifier: identifier, non_null_args: []}
  end

  @doc """
  Builds a Graphql query string.
  """
  @spec graphql_query(
          query_name :: atom,
          query_argument :: keyword,
          query_fields :: keyword
        ) :: String.t()
  def graphql_query(name, args \\ [], fields) do
    arg_str = build_args(args)
    field_str = prepare_fields(fields)

    "{#{name}#{arg_str}#{field_str}}"
  end

  @doc """
  Builds a Graphql Relay `node` query string.
  `query_id` is converted to the Global ID.
  """
  @spec graphql_node_query(
          query_type :: atom,
          query_id :: String.t(),
          query_fields :: keyword
        ) :: String.t()
  def graphql_node_query(type, id, fields, opts \\ []) do
    global_id = Absinthe.Relay.Node.to_global_id(type, id, fetch_schema(opts))
    arg_str = build_args(id: global_id)
    field_str = prepare_fields(_on: [{type, fields}])

    "{node#{arg_str}#{field_str}}"
  end

  @doc """
  Same as `graphql_query/3`, but for mutations.
  """
  @spec graphql_mutation(
          query_name :: atom,
          query_argument :: keyword,
          query_fields :: keyword
        ) :: String.t()
  def graphql_mutation(name, args \\ [], fields) do
    arg_str = build_args(args)
    field_str = prepare_fields(fields)

    "mutation {#{name}#{arg_str}#{field_str}}"
  end

  @doc """
  Same as `graphql_query/3`, but for subscriptions.
  """
  @spec graphql_subscription(
          query_name :: atom,
          query_argument :: keyword,
          query_fields :: keyword
        ) :: String.t()
  def graphql_subscription(name, args \\ [], fields) do
    arg_str = build_args(args)
    field_str = prepare_fields(fields)

    "subscription {#{name}#{arg_str}#{field_str}}"
  end

  defp prepare_fields(fields) do
    field_str =
      fields
      |> Enum.map(&prepare_field/1)
      |> Enum.join(", ")

    if field_str == "", do: "", else: " {#{field_str}}"
  end

  defp prepare_field({:query, field, args, children})
       when is_atom(field) and is_list(children) do
    query = graphql_query(field, args, children)
    trim(query)
  end

  defp prepare_field({:query, %Query{identifier: identifier}, args, children})
       when is_atom(identifier) and is_list(children) do
    query = graphql_query(identifier, args, children)
    trim(query)
  end

  defp prepare_field({:_on, branches})
       when is_list(branches) do
    branches
    |> Enum.map(fn {type, fields} ->
      camelized_type = type |> to_string |> Absinthe.Utils.camelize()
      "... on #{camelized_type} #{prepare_fields(fields)}"
    end)
    |> Enum.join(" ")
  end

  defp prepare_field({field, children})
       when is_atom(field) and is_list(children) do
    to_string(field) <> prepare_fields(children)
  end

  defp prepare_field(field) when is_atom(field), do: field

  defp build_args(args) do
    case stringify(args) do
      "" -> ""
      # only happens empty argument
      "[]" -> ""
      s -> "(#{trim(s)})"
    end
  end

  defp stringify([]), do: "[]"
  defp stringify(nil), do: "null"
  defp stringify(v) when is_binary(v), do: inspect(v)
  defp stringify(v) when is_boolean(v), do: to_string(v)
  defp stringify(v) when is_atom(v), do: v |> to_string() |> String.upcase()
  defp stringify(v) when is_struct(v), do: stringify(Map.from_struct(v))

  defp stringify(v) when is_list(v) or is_map(v) do
    if Keyword.keyword?(v) || is_map(v) do
      Enum.map(v, fn {key, value} -> "#{key}: #{stringify(value)}" end)
      |> Enum.join(", ")
      |> (&"{#{&1}}").()
    else
      Enum.map(v, &stringify/1)
      |> Enum.join(", ")
      |> (&"[#{&1}]").()
    end
  end

  defp stringify(v) when is_number(v), do: v

  defp trim(s) when is_binary(s),
    do: s |> String.replace_prefix("{", "") |> String.replace_suffix("}", "")

  @doc """
  Returns all fields of an object as list. Can be used together with the Graphql
  query builder functions.

  ## Options
  - `complexity`: maximum depth to be resolved.
    this is used to prevent from recurring infinitely.
  - `schema`: schema to look up fields
  """
  def fields(type, opts \\ [complexity: @complexity, schema: @schema])

  def fields(nil, _), do: raise(ArgumentError, "type not found")

  def fields(type, opts) when is_atom(type) do
    opts
    |> fetch_schema()
    |> Absinthe.Schema.lookup_type(type)
    |> fields(opts)
  end

  def fields(%Type.Field{type: type}, opts) do
    opts
    |> fetch_schema()
    |> Absinthe.Schema.lookup_type(type)
    |> fields(opts)
  end

  def fields(%Type.Object{fields: fields}, opts) do
    next_opts = reduce_complexity(opts)

    fields
    |> Map.delete(:__typename)
    |> Enum.map(fn
      {identifier, type} ->
        to_list_children(identifier, type, next_opts)
    end)
    |> exclude_skip()
  end

  def fields(type, opts)
      when is_module(type, Type.Interface) or is_module(type, Type.Union) do
    next_opts = reduce_complexity(opts)

    concrete_type_fields =
      opts
      |> fetch_schema()
      |> Absinthe.Schema.concrete_types(type)
      |> Enum.map(fn
        %Type.Object{identifier: identifier} = object ->
          to_list_children(identifier, object, next_opts)

        _ ->
          :_skip
      end)
      |> exclude_skip()

    if [] == concrete_type_fields do
      []
    else
      [{:_on, concrete_type_fields}]
    end
  end

  def fields(%Type.Enum{}, _), do: :_identifier
  def fields(%Type.Scalar{}, _), do: :_identifier

  defp exclude_skip(list), do: Enum.reject(list, &(&1 == :_skip))

  defp to_list_children(identifier, type, opts) do
    complexity = opts[:complexity]

    if complexity < 0 do
      :_skip
    else
      case fields(type, opts) do
        :_identifier ->
          case Query.new(identifier, type) do
            %Query{non_null_args: [_ | _]} = query ->
              {:query, query, [], []}

            %Query{non_null_args: []} ->
              identifier
          end

        # object without children is invalid
        [] ->
          :_skip

        children when is_list(children) ->
          case Query.new(identifier, type) do
            %Query{non_null_args: [_ | _]} = query ->
              {:query, query, [], children}

            %Query{non_null_args: []} ->
              {identifier, children}
          end

        _ ->
          :_skip
      end
    end
  end

  defp fetch_schema(opts), do: Keyword.get(opts, :schema, @schema)

  defp reduce_complexity(opts) do
    {_, next} = Keyword.get_and_update!(opts, :complexity, &{&1, &1 - 1})
    next
  end

  @doc """
  Set query argument in a nested field
  """
  @spec argument_fields(query_fields :: keyword, query_argument :: keyword) ::
          keyword
  def argument_fields(fields, args) when is_list(fields) and is_list(args) do
    Enum.reduce(args, fields, fn {key, args}, acc ->
      insert_argument_fields(acc, key, args)
    end)
  end

  defp insert_argument_fields(fields, key, args)
       when is_list(fields) and is_atom(key) do
    Enum.map(fields, fn
      {:query, %Query{identifier: query_key} = query, query_args, children}
      when key == query_key ->
        query_args = Map.merge(Map.new(query_args), Map.new(args))

        {:query, query, query_args, insert_argument_fields(children, key, args)}

      {:query, %Query{identifier: query_key} = query, query_args, children}
      when key != query_key ->
        {:query, query, query_args, insert_argument_fields(children, key, args)}

      {:query, query_key, query_args, children} when key == query_key ->
        query_args = Map.merge(Map.new(query_args), Map.new(args))

        {:query, query_key, query_args,
         insert_argument_fields(children, key, args)}

      {:query, query_key, query_args, children} when key != query_key ->
        {:query, query_key, query_args,
         insert_argument_fields(children, key, args)}

      # union/interface can not have argument
      {:_on, field, children} ->
        {:on_, field, insert_argument_fields(children, key, args)}

      {field, children} when field == key ->
        {:query, key, args, children}

      {field, children} when field != key ->
        {field, insert_argument_fields(children, key, args)}

      field when field == key ->
        {:query, key, args, []}

      field ->
        field
    end)
  end

  @doc """
  Drop invalid query fields
  ex. having required arguments but they are not set
  """
  @spec drop_invalid_query_fields(query_fields :: keyword) :: keyword
  def drop_invalid_query_fields(fields) when is_list(fields) do
    Enum.map(fields, fn
      {:query, %Query{non_null_args: non_null_args} = query, args, children} ->
        has_invalid =
          MapSet.subset?(MapSet.new(non_null_args), MapSet.new(args))

        children = drop_invalid_query_fields(children)

        case {has_invalid, children} do
          {true, _} -> :_skip
          {false, []} -> :_skip
          {false, children} -> {:query, query, args, children}
        end

      {:_on, field, children} ->
        case drop_invalid_query_fields(children) do
          [] -> :_skip
          children -> {:_on, field, children}
        end

      {field, children} ->
        case drop_invalid_query_fields(children) do
          [] -> :_skip
          children -> {field, children}
        end

      field ->
        field
    end)
    |> exclude_skip()
  end

  @doc """
  Drop query fields
  """
  @spec drop_fields(query_fields :: keyword, drop_fields :: [atom]) ::
          keyword
  def drop_fields(fields, keys)
      when is_list(fields) and is_list(keys) do
    Enum.reduce(keys, fields, fn key, acc ->
      drop_field(acc, key)
    end)
  end

  defp drop_field(fields, key)
       when is_list(fields) and is_atom(key) do
    Enum.map(fields, fn
      {:_on, field, _} when field == key ->
        :_skip

      {:_on, field, children} when field != key ->
        drop_field(children, key)

      {:query, %Query{identifier: field}, _, _} when field == key ->
        :_skip

      {:query, %Query{identifier: field} = query, args, children}
      when field != key ->
        {:query, query, args, drop_field(children, key)}

      {:query, field, _, _} when field == key ->
        :_skip

      {:query, field, args, children} when field != key ->
        {:query, field, args, drop_field(children, key)}

      {field, _} when field == key ->
        :_skip

      {field, children} when field != key ->
        {field, drop_field(children, key)}

      field when field == key ->
        :_skip

      field ->
        field
    end)
    |> exclude_skip()
  end

  @doc """
  Same as `fields/2` but with relay pagination fields
  """
  def paginated_fields(type, opts \\ [complexity: @complexity, schema: @schema]) do
    [
      edges: [:cursor, node: fields(type, opts)],
      page_info: [
        :start_cursor,
        :end_cursor,
        :has_next_page,
        :has_previous_page
      ]
    ]
  end
end
