defmodule AbsintheExtra.Support.TestSchema do
  @moduledoc false

  use Absinthe.Schema

  query do
    field :user, :user do
      resolve fn _, _ -> {:ok, %{name: "name", age: :one}} end
    end

    field :argument_field_user, :argument_field_user do
      arg :parent, non_null(:boolean)
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end

    field :interface_user, :interface_user do
      resolve fn _, _ -> {:ok, %{name: "name"}} end
    end
  end

  ## query user

  enum :age do
    value :one
    value :two
  end

  object :user do
    field :name, non_null(:string)
    field :age, non_null(:age)
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
