defmodule Absinthe.Extra.Middleware.Policy do
  @moduledoc false

  alias Absinthe.Resolution
  alias Absinthe.Schema.Notation

  defmacro policy(module, opts \\ []) do
    quote do
      Notation.middleware(
        unquote(module),
        {unquote(module), unquote(opts)}
      )
    end
  end

  defmacro __using__(_) do
    quote do
      @behaviour Absinthe.Middleware

      @impl true
      def call(
            %Absinthe.Resolution{} = resolution,
            {module, opts}
          ) do
        identifier = resolution.definition.schema_node.identifier

        apply(module, identifier, [resolution, opts])
      end
    end
  end

  @spec policy_allow(resolution :: Resolution.t()) :: Resolution.t()
  def policy_allow(resolution) do
    resolution
  end

  @spec policy_deny(resolution :: Resolution.t()) :: Resolution.t()
  def policy_deny(resolution) do
    Resolution.put_result(resolution, {:error, :policy_denied})
  end
end
