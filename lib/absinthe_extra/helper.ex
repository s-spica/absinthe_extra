defmodule AbsintheExtra.Helper do
  @moduledoc false

  import :erlang, only: [map_get: 2]

  defguard is_module(struct, module)
           when is_struct(struct) and map_get(:__struct__, struct) == module
end
