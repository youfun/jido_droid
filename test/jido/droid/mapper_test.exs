defmodule Jido.Droid.MapperTest do
  use ExUnit.Case, async: true

  alias Jido.Droid.Mapper
  alias Jido.Harness.Event

  describe "map_event/2" do
    test "maps system event" do
      json = %{
        "type" => "system",
        "session_id" => "session-1",
        "timestamp" => 1_709_481_600_000,
        "model" => "claude-3-5-sonnet-20241022",
        "tools" => ["Read", "Edit"],
        "cwd" => "/project"
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :system
      assert event.provider == :droid
      assert event.session_id == "session-1"
      assert event.payload["model"] == "claude-3-5-sonnet-20241022"
      assert event.payload["tools"] == ["Read", "Edit"]
      assert event.payload["cwd"] == "/project"
    end

    test "maps user message" do
      json = %{
        "type" => "message",
        "role" => "user",
        "text" => "Hello",
        "id" => "msg-1"
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :user_message
      assert event.payload["role"] == "user"
      assert event.payload["text"] == "Hello"
    end

    test "maps assistant message" do
      json = %{
        "type" => "message",
        "role" => "assistant",
        "text" => "Hi there",
        "id" => "msg-2"
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :assistant_message
      assert event.payload["text"] == "Hi there"
    end

    test "maps tool_call event" do
      json = %{
        "type" => "tool_call",
        "toolName" => "Read",
        "toolId" => "tool-1",
        "parameters" => %{"file_path" => "test.ex"},
        "id" => "call-1"
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :tool_use
      assert event.payload["tool_name"] == "Read"
      assert event.payload["tool_id"] == "tool-1"
      assert event.payload["parameters"]["file_path"] == "test.ex"
    end

    test "maps tool_result event" do
      json = %{
        "type" => "tool_result",
        "toolId" => "tool-1",
        "value" => "file contents",
        "isError" => false,
        "id" => "result-1"
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :tool_result
      assert event.payload["tool_id"] == "tool-1"
      assert event.payload["value"] == "file contents"
      assert event.payload["is_error"] == false
    end

    test "maps completion event" do
      json = %{
        "type" => "completion",
        "finalText" => "Done!",
        "numTurns" => 5,
        "durationMs" => 12_345
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.type == :result
      assert event.payload["final_text"] == "Done!"
      assert event.payload["num_turns"] == 5
      assert event.payload["duration_ms"] == 12_345
    end

    test "converts integer timestamp to ISO8601" do
      json = %{
        "type" => "system",
        "timestamp" => 1_709_481_600_000
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert is_binary(event.timestamp)
      assert String.contains?(event.timestamp, "T")
    end

    test "preserves string timestamp" do
      timestamp = "2024-03-03T12:00:00Z"

      json = %{
        "type" => "system",
        "timestamp" => timestamp
      }

      assert {:ok, %Event{} = event} = Mapper.map_event(json)
      assert event.timestamp == timestamp
    end
  end
end
