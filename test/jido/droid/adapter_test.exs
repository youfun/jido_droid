defmodule Jido.Droid.AdapterTest do
  use ExUnit.Case, async: false

  use Jido.Harness.AdapterContract,
    adapter: Jido.Droid.Adapter,
    provider: :droid,
    check_run: false,
    run_request: %{prompt: "contract droid run", cwd: "/repo", metadata: %{}}

  alias Jido.Droid.Adapter
  alias Jido.Droid.Test.{Fixtures, StubCLI, StubCLINotFound, StubCompatibility, StubCompatibilityFailed, StubStream}

  setup do
    # Store original config
    original_cli = Application.get_env(:jido_droid, :cli_module)
    original_compat = Application.get_env(:jido_droid, :compatibility_module)
    original_stream = Application.get_env(:jido_droid, :stream_module)

    on_exit(fn ->
      # Restore original config
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

  describe "id/0 and capabilities/0" do
    test "returns correct provider id" do
      assert Adapter.id() == :droid
    end

    test "returns capabilities" do
      caps = Adapter.capabilities()
      assert caps.streaming? == true
      assert caps.tool_calls? == true
      assert caps.tool_results? == true
      assert caps.thinking? == true
      assert caps.cancellation? == false
    end
  end

  describe "runtime_contract/0" do
    test "exposes droid runtime requirements" do
      contract = Adapter.runtime_contract()
      assert contract.provider == :droid
      assert "FACTORY_API_KEY" in contract.host_env_required_any
      assert "droid" in contract.runtime_tools_required
      assert is_list(contract.compatibility_probes)

      assert Enum.any?(contract.compatibility_probes, fn probe ->
               probe["command"] == "droid --version"
             end)

      assert String.contains?(contract.triage_command_template, "droid exec")
      assert String.contains?(contract.coding_command_template, "--auto medium")
    end
  end

  describe "cancel/1" do
    test "returns not_supported error" do
      assert {:error, :not_supported} = Adapter.cancel("session-123")
    end
  end

  describe "run/2 with module injection" do
    test "successfully runs with stubbed modules" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      request = Fixtures.run_request()
      assert {:ok, stream} = Adapter.run(request)
      assert is_struct(stream, Stream)
    end

    test "returns error when CLI not found" do
      Application.put_env(:jido_droid, :cli_module, StubCLINotFound)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)

      request = Fixtures.run_request()
      assert {:error, :not_found} = Adapter.run(request)
    end

    test "returns error when compatibility check fails" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibilityFailed)

      request = Fixtures.run_request()
      assert {:error, :incompatible} = Adapter.run(request)
    end

    test "passes options to stream builder" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      request = Fixtures.run_request()
      assert {:ok, _stream} = Adapter.run(request, auto: "high")
    end

    test "handles different request configurations" do
      Application.put_env(:jido_droid, :cli_module, StubCLI)
      Application.put_env(:jido_droid, :compatibility_module, StubCompatibility)
      Application.put_env(:jido_droid, :stream_module, StubStream)

      request =
        Fixtures.run_request(
          model: "claude-3-opus-20240229",
          allowed_tools: ["Read", "Edit"],
          metadata: %{"session_id" => "test-123"}
        )

      assert {:ok, _stream} = Adapter.run(request)
    end
  end
end
