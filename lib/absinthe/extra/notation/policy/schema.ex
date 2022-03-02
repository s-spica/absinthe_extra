defmodule Absinthe.Extra.Notation.Policy.Schema do
  @moduledoc false

  alias Absinthe.Resolution

  @spec allow(resolution :: Resolution.t()) :: Resolution.t()
  def allow(resolution) do
    resolution
  end

  @spec deny(resolution :: Resolution.t()) :: Resolution.t()
  def deny(resolution) do
    Resolution.put_result(resolution, {:error, :policy_denied})
  end
end
