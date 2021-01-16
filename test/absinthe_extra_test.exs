defmodule AbsintheExtraTest do
  use ExUnit.Case
  doctest AbsintheExtra

  test "greets the world" do
    assert AbsintheExtra.hello() == :world
  end
end
