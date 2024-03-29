defmodule Absinthe.Extra.Support.TestSchema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  query do
    field :user, :user do
      resolve fn _, _ -> {:ok, %{name: "name", age: :one, id: "id"}} end
    end

    field :argument_user, :argument_user do
      arg :parent, non_null(:boolean)
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :optional_argument_user, :optional_argument_user do
      arg :parent, :boolean
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :interface_user, :interface_user do
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :nested_user, :nested_user do
      resolve fn _, _ -> {:ok, %{name: "name", user: %{name: "name"}}} end
    end

    node field do
      resolve fn
        %{type: :user, id: id}, _ ->
          {:ok, %{id: id, name: "name", age: :one}}
      end
    end
  end

  ## node user

  enum :age do
    value :one
    value :two
  end

  node interface do
    resolve_type fn
      _, _ -> :user
    end
  end

  node object(:user) do
    field :name, non_null(:string)
    field :age, non_null(:age)
  end

  ## argument user

  object :argument_user do
    field :name, :string do
      arg :child, non_null(:boolean)
    end

    field :argument_user, :argument_user do
      arg :name, non_null(:string)

      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :optional_user, :argument_user do
      arg :name, :string

      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end
  end

  object :optional_argument_user do
    field :name, :string do
      arg :child, :boolean
    end

    field :user, :optional_argument_user do
      arg :name, :string

      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end
  end

  ## interface user

  interface :interface_user do
    field :name, :string
    resolve_type fn _, _ -> :interface_concrete_user end
  end

  object :interface_concrete_user do
    field :name, :string
    field :user, :interface_user, resolve: fn _, _ -> {:ok, %{name: "name"}} end

    interface :interface_user
  end

  ## nested user

  object :nested_user do
    field :name, :string
    field :user, :nested_user
  end
end
