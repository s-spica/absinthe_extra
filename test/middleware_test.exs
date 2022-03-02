defmodule Absinthe.Extra.MiddlewareTest do
  use ExUnit.Case, async: true

  defmodule TestPolicy do
    use Absinthe.Extra.Middleware.Policy

    import Absinthe.Extra.Middleware.Policy,
      only: [policy_allow: 1, policy_deny: 1]

    def allow(resolution, _) do
      policy_allow(resolution)
    end

    def deny(resolution, _) do
      policy_deny(resolution)
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    import Absinthe.Extra.Middleware.Policy, only: [policy: 1]

    query do
      field :allow, :boolean do
        policy TestPolicy
        resolve fn _, _ -> {:ok, true} end
      end

      field :deny, :boolean do
        policy TestPolicy
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
