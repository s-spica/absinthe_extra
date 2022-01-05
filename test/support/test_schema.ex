defmodule AbsintheExtra.Support.TestSchema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  query do
    field :user, :user do
      resolve fn _, _ -> {:ok, %{name: "name", age: :one, id: "id"}} end
    end

    field :argument_field_user, :argument_field_user do
      arg :parent, non_null(:boolean)
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :interface_user, :interface_user do
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    node field do
      resolve fn
        %{type: :user, id: id}, _ ->
          {:ok, %{id: id, name: "name", age: :one}}
      end
    end
  end

  ## object user

  enum :age do
    value :one
    value :two
  end

  node object(:user) do
    field :name, non_null(:string)
    field :age, non_null(:age)
  end

  node interface do
    resolve_type fn
      _, _ -> :user
    end
  end

  ## query argument_field_user

  object :argument_field_user do
    field :name, :string do
      arg :child, non_null(:boolean)
    end
  end

  ## query interface_user

  interface :interface_user do
    field :name, :string
    resolve_type fn _, _ -> :interface_concrete_user end
  end

  object :interface_concrete_user do
    field :name, :string
    field :user, :interface_user, resolve: fn _, _ -> {:ok, %{name: "name"}} end

    interface :interface_user
  end
end
