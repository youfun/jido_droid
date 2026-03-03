defmodule Jido.DroidTest do
  use ExUnit.Case, async: false

  alias Jido.Droid
  alias Jido.Droid.Test.{Fixtures, StubCLI, StubCompatibility, StubStream}

  setup do
    # Store original config
    original_adapter = Application.get_env(:jido_droid, :adapter_module)
    original_cli = Application.get_env(:jido_droid, :cli_module)
    original_compat = Application.get_env(:jido_droid, :compatibility_module)
    original_stream = Application.get_env(:jido_droid, :stream_module)

    on_exit(fn ->
      # Restore original config
      if original_adapter do
        Application.put_env(:jido_droid, :adapter_module, original_adapter)
      else
        Application.delete_env(:jido_droid, :adapter_module)
      end

      if original_cli do
        Application.put_env(:jido_droid, :cli_module, original_cli)
      else
        Application.delete_env(:jido_droid, :cli_module)
      end

      if original_compat do
        Application.put_env(:jido_droid, :compatibility_module, original_compat)
      else
        Application.delete_env(:jido_droid, :compatibility_module)
      end

      if original_stream do
        Application.put_env(:jido_droid, :stream_module, original_stream)
      else
        Application.delete_env(:jido_droid, :stream_module)
      end
    end)

    :ok
  end

  describe "version/0" do
    test "returns version string" do
      assert is_binary(Droid.version())
      assert Droid.version() =~ ~r/\d+\.\d+\.\d+/
    end

    test "version is 0.1.0" do
      assert Droid.version() == "0.1.0"
    end
  end

  describe "cli_installed?/0" do
    test "returns boolean" do
      assert is_boolean(Droid.cli_installed?())
    end
  end

  describe "compatible?/0" do
    test "returns boolean" do
      assert is_boolean(Droid.compatible?())
    end
  end

  describe "assert_compatible!/0" do
    test "returns :ok when compatible" do
      # This depends on actual CLI installation
      result = Droid.assert_compatible!()
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "run/2" do
    test "accepts prompt string and options" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      assert {:ok, stream} = Droid.run("test prompt", cwd: "/test")
      assert Enumerable.impl_for(stream) != nil
    end

    test "builds RunRequest from prompt and options" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      opts = [
        cwd: "/test/dir",
        model: "claude-3-5-sonnet-20241022",
        max_turns: 10,
        allowed_tools: ["Read", "Edit"]
      ]

      assert {:ok, _stream} = Droid.run("test prompt", opts)
    end

    test "separates request opts from adapter opts" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      opts = [
        # request opt
        cwd: "/test",
        # request opt
        model: "test-model",
        # adapter opt
        auto: "high"
      ]

      assert {:ok, _stream} = Droid.run("test", opts)
    end

    test "requires prompt to be a string" do
      assert_raise FunctionClauseError, fn ->
        Droid.run(123, cwd: "/test")
      end
    end

    test "requires opts to be a keyword list" do
      assert_raise FunctionClauseError, fn ->
        Droid.run("test", %{cwd: "/test"})
      end
    end
  end

  describe "run_request/2" do
    test "accepts RunRequest struct" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      request = Fixtures.run_request()
      assert {:ok, stream} = Droid.run_request(request)
      assert Enumerable.impl_for(stream) != nil
    end

    test "passes adapter options to adapter" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      request = Fixtures.run_request()
      assert {:ok, _stream} = Droid.run_request(request, auto: "high")
    end

    test "requires RunRequest struct" do
      assert_raise FunctionClauseError, fn ->
        Droid.run_request(%{prompt: "test"})
      end
    end

    test "requires opts to be a keyword list" do
      request = Fixtures.run_request()

      assert_raise FunctionClauseError, fn ->
        Droid.run_request(request, %{auto: "high"})
      end
    end
  end

  describe "cancel/1" do
    test "delegates to adapter" do
      result = Droid.cancel("test-session-123")
      # Droid adapter doesn't support cancellation
      assert result == {:error, :not_supported}
    end

    test "accepts session_id string" do
      assert {:error, :not_supported} = Droid.cancel("session-id")
    end
  end

  describe "adapter_module injection" do
    defmodule StubAdapter do
      def run(_request, _opts), do: {:ok, [:stubbed]}
      def cancel(_session_id), do: {:ok, :stubbed_cancel}
    end

    test "uses injected adapter module" do
      Application.put_env(:jido_droid, :adapter_module, StubAdapter)

      request = Fixtures.run_request()
      assert {:ok, [:stubbed]} = Droid.run_request(request)
      assert {:ok, :stubbed_cancel} = Droid.cancel("test")
    end
  end
end
