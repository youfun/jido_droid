defmodule Jido.Droid.Integration.EndToEndTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Jido.Droid
  alias Jido.Harness.RunRequest

  describe "end-to-end execution with real Droid CLI" do
    @tag timeout: 60_000
    test "runs a simple prompt and receives events" do
      # Skip if Droid CLI is not installed
      unless Droid.cli_installed?() do
        IO.puts("Skipping: Droid CLI not installed")
        :ok
      else
        # Run a minimal prompt
        result = Droid.run("Say hello in one word", cwd: ".", timeout_ms: 30_000)

        case result do
          {:ok, stream} ->
            # Collect events
            events = stream |> Enum.take(100) |> Enum.to_list()

            # Verify we got events
            assert length(events) > 0, "Should receive at least one event"

            # Verify event structure
            Enum.each(events, fn event ->
              assert %Jido.Harness.Event{} = event
              assert event.provider == :droid
              assert is_atom(event.type)
              assert is_map(event.payload)
              # Timestamp can be nil or a DateTime
              if event.timestamp do
                assert %DateTime{} = event.timestamp
              end
            end)

            # Should have a system event
            system_events = Enum.filter(events, &(&1.type == :system))
            assert length(system_events) > 0, "Should have at least one system event"

            # Should have a result/completion event
            completion_events = Enum.filter(events, &(&1.type in [:result, :completion]))
            assert length(completion_events) > 0, "Should have a completion event"

            IO.puts("\n✓ End-to-end test passed with #{length(events)} events")

          {:error, reason} ->
            flunk("Failed to run prompt: #{inspect(reason)}")
        end
      end
    end

    @tag timeout: 60_000
    test "runs with RunRequest and custom options" do
      unless Droid.cli_installed?() do
        IO.puts("Skipping: Droid CLI not installed")
        :ok
      else
        request =
          RunRequest.new!(%{
            prompt: "Echo 'test'",
            cwd: ".",
            timeout_ms: 30_000,
            metadata: %{"test" => "e2e"}
          })

        result = Droid.run_request(request, auto: "low")

        case result do
          {:ok, stream} ->
            events = stream |> Enum.take(100) |> Enum.to_list()
            assert length(events) > 0

            IO.puts("\n✓ RunRequest test passed with #{length(events)} events")

          {:error, reason} ->
            flunk("Failed to run request: #{inspect(reason)}")
        end
      end
    end

    @tag timeout: 60_000
    test "handles different event types" do
      unless Droid.cli_installed?() do
        IO.puts("Skipping: Droid CLI not installed")
        :ok
      else
        result = Droid.run("List files in current directory", cwd: ".", timeout_ms: 30_000)

        case result do
          {:ok, stream} ->
            events = stream |> Enum.take(100) |> Enum.to_list()

            # Collect event types
            event_types = events |> Enum.map(& &1.type) |> Enum.uniq()

            IO.puts("\n✓ Received event types: #{inspect(event_types)}")

            # Should have various event types
            assert :system in event_types, "Should have system event"

            # At least one of these should be present
            has_content =
              Enum.any?(event_types, fn type ->
                type in [:text, :user_message, :assistant_message, :tool_use, :tool_result]
              end)

            assert has_content, "Should have content events"

          {:error, reason} ->
            flunk("Failed to run prompt: #{inspect(reason)}")
        end
      end
    end
  end

  describe "compatibility checks" do
    test "cli_installed? returns boolean" do
      result = Droid.cli_installed?()
      assert is_boolean(result)
    end

    test "compatible? returns boolean" do
      result = Droid.compatible?()
      assert is_boolean(result)
    end

    test "assert_compatible! succeeds or raises" do
      if Droid.cli_installed?() do
        # Should not raise if CLI is installed
        assert :ok = Droid.assert_compatible!()
      else
        # Should raise if CLI is not installed
        assert_raise Jido.Droid.Error.ConfigError, fn ->
          Droid.assert_compatible!()
        end
      end
    end
  end

  describe "error handling" do
    test "handles invalid cwd gracefully" do
      result = Droid.run("test", cwd: "/nonexistent/path/that/does/not/exist")

      # Should either fail immediately or during stream consumption
      case result do
        {:ok, stream} ->
          # Try to consume the stream - might succeed or fail depending on CLI behavior
          events = stream |> Enum.take(10) |> Enum.to_list()
          # If we get here, CLI handled the invalid path gracefully
          assert is_list(events)

        {:error, _reason} ->
          # Expected error
          assert true
      end
    end

    test "cancel returns not_supported" do
      assert {:error, :not_supported} = Droid.cancel("any-session-id")
    end
  end
end
