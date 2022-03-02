defmodule Absinthe.Extra.Notation.Policy do
  @moduledoc false

  alias Absinthe.Schema.Notation
  alias Absinthe.Extra.Notation.Policy.Middleware

  defmacro policy(module, func, opts \\ []) do
    quote do
      Notation.middleware(
        Middleware,
        {unquote(module), unquote(func), unquote(opts)}
      )
    end
  end
end
