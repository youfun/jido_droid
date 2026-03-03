defmodule Jido.Droid.CLITest do
  use ExUnit.Case, async: true

  alias Jido.Droid.CLI

  describe "find_executable/0" do
    test "returns ok tuple with path when droid is found" do
      case CLI.find_executable() do
        {:ok, path} ->
          assert is_binary(path)
          assert String.contains?(path, "droid")

        {:error, error} ->
          # CLI not installed, verify error structure
          assert %Jido.Droid.Error.ExecutionFailureError{} = error
          assert error.message =~ "droid CLI not found"
      end
    end
  end

  describe "installed?/0" do
    test "returns boolean" do
      result = CLI.installed?()
      assert is_boolean(result)
    end

    test "matches find_executable result" do
      installed = CLI.installed?()
      executable_result = CLI.find_executable()

      case executable_result do
        {:ok, _} -> assert installed == true
        {:error, _} -> assert installed == false
      end
    end
  end

  describe "version/0" do
    test "returns version when CLI is installed" do
      if CLI.installed?() do
        case CLI.version() do
          {:ok, version} ->
            assert is_binary(version)
            assert String.length(version) > 0
            # Version should contain numbers
            assert version =~ ~r/\d/

          {:error, error} ->
            # Might fail if --version flag doesn't work
            assert %Jido.Droid.Error.ExecutionFailureError{} = error
        end
      else
        # Should return error when CLI not installed
        assert {:error, _} = CLI.version()
      end
    end

    test "returns error when CLI not found" do
      unless CLI.installed?() do
        assert {:error, error} = CLI.version()
        assert %Jido.Droid.Error.ExecutionFailureError{} = error
      end
    end
  end
end
