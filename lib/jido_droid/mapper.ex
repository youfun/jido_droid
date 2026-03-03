defmodule Jido.Droid.Mapper do
  @moduledoc """
  Maps Droid CLI JSONL events to normalized `Jido.Harness.Event` structs.
  """

  alias Jido.Harness.Event

  @doc """
  Maps a Droid JSON event to a normalized Harness event.
  """
  @spec map_event(map(), keyword()) :: {:ok, Event.t()} | {:error, term()}
  def map_event(json, _opts \\ []) when is_map(json) do
    type = map_type(json)
    session_id = Map.get(json, "session_id")
    timestamp = Map.get(json, "timestamp") |> maybe_to_iso8601()

    event =
      Event.new!(%{
        type: type,
        provider: :droid,
        session_id: session_id,
        timestamp: timestamp,
        payload: build_payload(json),
        raw: json
      })

    {:ok, event}
  rescue
    e -> {:error, e}
  end

  defp map_type(%{"type" => "system"}), do: :system
  defp map_type(%{"type" => "message", "role" => "user"}), do: :user_message
  defp map_type(%{"type" => "message", "role" => "assistant"}), do: :assistant_message
  defp map_type(%{"type" => "tool_call"}), do: :tool_use
  defp map_type(%{"type" => "tool_result"}), do: :tool_result
  defp map_type(%{"type" => "completion"}), do: :result
  defp map_type(%{"type" => "result"}), do: :result
  defp map_type(%{"type" => type}), do: String.to_atom(type)
  defp map_type(_), do: :unknown

  defp build_payload(%{"type" => "system"} = json) do
    %{
      "model" => Map.get(json, "model"),
      "tools" => Map.get(json, "tools", []),
      "cwd" => Map.get(json, "cwd")
    }
  end

  defp build_payload(%{"type" => "message"} = json) do
    %{
      "role" => Map.get(json, "role"),
      "text" => Map.get(json, "text"),
      "id" => Map.get(json, "id")
    }
  end

  defp build_payload(%{"type" => "tool_call"} = json) do
    %{
      "tool_name" => Map.get(json, "toolName"),
      "tool_id" => Map.get(json, "toolId"),
      "parameters" => Map.get(json, "parameters", %{}),
      "id" => Map.get(json, "id")
    }
  end

  defp build_payload(%{"type" => "tool_result"} = json) do
    %{
      "tool_id" => Map.get(json, "toolId"),
      "value" => Map.get(json, "value"),
      "is_error" => Map.get(json, "isError", false),
      "id" => Map.get(json, "id")
    }
  end

  defp build_payload(%{"type" => "completion"} = json) do
    %{
      "final_text" => Map.get(json, "finalText"),
      "num_turns" => Map.get(json, "numTurns"),
      "duration_ms" => Map.get(json, "durationMs")
    }
  end

  defp build_payload(json), do: json

  defp maybe_to_iso8601(nil), do: nil

  defp maybe_to_iso8601(ts) when is_integer(ts) do
    ts
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_iso8601()
  end

  defp maybe_to_iso8601(ts) when is_binary(ts), do: ts
  defp maybe_to_iso8601(_), do: nil
end
