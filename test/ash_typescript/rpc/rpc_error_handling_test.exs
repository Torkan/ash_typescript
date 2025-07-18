defmodule AshTypescript.Rpc.ErrorHandlingTest do
  use ExUnit.Case, async: true
  import AshTypescript.Test.TestHelpers
  alias AshTypescript.Rpc

  setup do
    conn = build_rpc_conn()
    {:ok, conn: conn}
  end

  describe "error handling" do
    test "returns error for non-existent action", %{conn: conn} do
      params = %{
        "action" => "nonexistent_action",
        "fields" => [],
        "input" => %{}
      }

      assert_raise(RuntimeError, fn ->
        Rpc.run_action(:ash_typescript, conn, params)
      end)
    end

    test "returns error for non-existent action in validation", %{conn: conn} do
      params = %{
        "action" => "nonexistent_action",
        "input" => %{}
      }

      assert_raise(RuntimeError, fn ->
        Rpc.validate_action(:ash_typescript, conn, params)
      end)
    end
  end
end
