defmodule Jido.Droid.Stream do
  @moduledoc """
  Builds event streams from Droid CLI process output.
  """

  alias Jido.Droid.Mapper
  alias Jido.Harness.{Event, RunRequest}

  @doc """
  Builds an event stream from a Droid CLI process.
  """
  @spec build(String.t(), list(String.t()), RunRequest.t()) :: Enumerable.t(Event.t())
  def build(droid_path, args, request) do
    Stream.resource(
      fn -> start_port(droid_path, args) end,
      fn
        nil ->
          {:halt, nil}

        {port, buffer} ->
          receive do
            {^port, {:data, data}} ->
              {events, new_buffer} = parse_buffer(buffer <> data, request)
              {events, {port, new_buffer}}

            {^port, {:exit_status, _code}} ->
              # Flush remaining buffer
              {events, _} = parse_buffer(buffer, request)
              {events, nil}
          after
            300_000 ->
              Port.close(port)
              {:halt, nil}
          end
      end,
      fn
        nil -> :ok
        {port, _} -> catch_port_close(port)
      end
    )
  end

  defp start_port(droid_path, args) do
    port =
      Port.open({:spawn_executable, droid_path}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: args
      ])

    {port, ""}
  end

  defp catch_port_close(port) do
    try do
      Port.close(port)
    rescue
      _ -> :ok
    catch
      _, _ -> :ok
    end
  end

  defp parse_buffer(data, _request) do
    lines = String.split(data, "\n")
    {complete_lines, [remainder]} = Enum.split(lines, -1)

    events =
      complete_lines
      |> Enum.reject(&(&1 == ""))
      |> Enum.flat_map(fn line ->
        case Jason.decode(line) do
          {:ok, json} when is_map(json) ->
            case Mapper.map_event(json) do
              {:ok, event} -> [event]
              {:error, _} -> []
            end

          _ ->
            []
        end
      end)

    {events, remainder}
  end
end
