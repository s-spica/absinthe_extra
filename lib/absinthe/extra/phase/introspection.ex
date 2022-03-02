defmodule Absinthe.Extra.Phase.Introspection do
  @moduledoc false

  use Absinthe.Phase

  def pipeline(config, opts) do
    Absinthe.Plug.default_pipeline(config, opts)
    |> Absinthe.Pipeline.insert_before(
      Absinthe.Phase.Document.Validation.Result,
      __MODULE__
    )
  end

  def run(%Absinthe.Blueprint{} = blueprint, _options) do
    result =
      Absinthe.Blueprint.update_current(blueprint, fn op ->
        Absinthe.Blueprint.prewalk(op, fn node ->
          if introspection?(node) do
            put_error(node, %Absinthe.Phase.Error{
              phase: __MODULE__,
              message: "unauthorized",
              locations: [node.source_location]
            })
          else
            node
          end
        end)
      end)

    {:ok, result}
  end

  def run(blueprint, _options) do
    {:ok, blueprint}
  end

  defp introspection?(%{name: "__schema"}), do: true
  defp introspection?(%{name: "__type"}), do: true
  defp introspection?(_), do: false
end
