defmodule AbsintheExtra.NotationTest do
  use ExUnit.Case, async: true

  defmodule TestPolicy do
    import AbsintheExtra.Notation.Policy.Schema

    def view_allow(resolution, _) do
      allow(resolution)
    end

    def view_deny(resolution, _) do
      deny(resolution)
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    import AbsintheExtra.Notation.Policy

    query do
      field :allow, :boolean do
        policy TestPolicy, :view_allow
        resolve fn _, _ -> {:ok, true} end
      end

      field :deny, :boolean do
        policy TestPolicy, :view_deny
        resolve fn _, _ -> {:ok, true} end
      end
    end
  end

  describe "policy/2" do
    test "allow" do
      query = "{allow}"

      assert {:ok, %{data: %{"allow" => true}}} ==
               Absinthe.run(query, TestSchema)
    end

    test "deny" do
      query = "{deny}"

      assert {:ok,
              %{
                data: %{"deny" => nil},
                errors: [
                  %{
                    locations: [%{column: 2, line: 1}],
                    message: "policy_denied",
                    path: ["deny"]
                  }
                ]
              }} == Absinthe.run(query, TestSchema)
    end
  end
end
