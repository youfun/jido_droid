defmodule Jido.Droid.Test.Fixtures do
  @moduledoc """
  Test fixtures for Jido.Droid tests.
  Provides sample Droid CLI events and expected outputs.
  """

  @doc "Sample system event from Droid CLI"
  def system_event(session_id \\ "test-session-123") do
    %{
      "type" => "system",
      "session_id" => session_id,
      "model" => "claude-3-5-sonnet-20241022",
      "timestamp" => 1_709_481_600_000
    }
  end

  @doc "Sample text event from Droid CLI"
  def text_event(text \\ "Hello, world!") do
    %{
      "type" => "text",
      "text" => text,
      "timestamp" => 1_709_481_601_000
    }
  end

  @doc "Sample tool_use event from Droid CLI"
  def tool_use_event(tool_name \\ "Read", tool_input \\ %{"file_path" => "/test/file.ex"}) do
    %{
      "type" => "tool_use",
      "tool_name" => tool_name,
      "tool_input" => tool_input,
      "timestamp" => 1_709_481_602_000
    }
  end

  @doc "Sample tool_result event from Droid CLI"
  def tool_result_event(tool_name \\ "Read", content \\ "file contents") do
    %{
      "type" => "tool_result",
      "tool_name" => tool_name,
      "content" => content,
      "timestamp" => 1_709_481_603_000
    }
  end

  @doc "Sample completion event from Droid CLI"
  def completion_event(session_id \\ "test-session-123") do
    %{
      "type" => "completion",
      "session_id" => session_id,
      "finalText" => "Task completed successfully!",
      "numTurns" => 5,
      "durationMs" => 12_345,
      "timestamp" => 1_709_481_604_000
    }
  end

  @doc "Sample error event from Droid CLI"
  def error_event(message \\ "Something went wrong") do
    %{
      "type" => "error",
      "error" => message,
      "timestamp" => 1_709_481_605_000
    }
  end

  @doc "Sample thinking event from Droid CLI"
  def thinking_event(content \\ "Analyzing the problem...") do
    %{
      "type" => "thinking",
      "content" => content,
      "timestamp" => 1_709_481_606_000
    }
  end

  @doc "Sample unknown event type"
  def unknown_event do
    %{
      "type" => "unknown_type",
      "data" => "some data",
      "timestamp" => 1_709_481_607_000
    }
  end

  @doc "JSONL string with multiple events"
  def jsonl_stream do
    [
      system_event(),
      text_event(),
      tool_use_event(),
      tool_result_event(),
      completion_event()
    ]
    |> Enum.map(&Jason.encode!/1)
    |> Enum.join("\n")
  end

  @doc "JSONL string with incomplete last line"
  def incomplete_jsonl_stream do
    complete = jsonl_stream()
    incomplete_line = ~s({"type":"text","text":"incomplete)
    complete <> "\n" <> incomplete_line
  end

  @doc "Sample RunRequest for testing"
  def run_request(opts \\ []) do
    defaults = [
      prompt: "Test prompt",
      cwd: ".",
      model: "claude-3-5-sonnet-20241022"
    ]

    Keyword.merge(defaults, opts)
    |> Map.new()
    |> Jido.Harness.RunRequest.new!()
  end

  @doc "Sample Harness Event for comparison"
  def harness_event(type, payload \\ %{}) do
    %Jido.Harness.Event{
      provider: :droid,
      type: type,
      payload: payload,
      timestamp: DateTime.utc_now()
    }
  end
end
