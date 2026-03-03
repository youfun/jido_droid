defmodule Jido.Droid.CompatibilityTest do
  use ExUnit.Case, async: true

  alias Jido.Droid.Compatibility

  describe "cli_installed?/0" do
    test "returns boolean" do
      assert is_boolean(Compatibility.cli_installed?())
    end
  end

  describe "compatible?/0" do
    test "returns boolean" do
      assert is_boolean(Compatibility.compatible?())
    end
  end

  describe "check/0" do
    test "returns :ok or error tuple" do
      result = Compatibility.check()
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "assert_compatible!/0" do
    test "returns :ok when compatible" do
      case Compatibility.check() do
        :ok ->
          assert :ok = Compatibility.assert_compatible!()

        {:error, _} ->
          assert_raise Jido.Droid.Error.ConfigError, fn ->
            Compatibility.assert_compatible!()
          end
      end
    end
  end
end
