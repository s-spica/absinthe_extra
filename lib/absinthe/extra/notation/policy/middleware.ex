defmodule Absinthe.Extra.Notation.Policy.Middleware do
  @moduledoc false

  @behaviour Absinthe.Middleware

  @impl true
  def call(resolution, {module, func, opts}) do
    apply(module, func, [resolution, opts])
  end
end
