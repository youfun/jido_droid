defmodule Mix.Tasks.Droid.Smoke do
  @moduledoc """
  Execute a minimal Droid prompt for smoke validation.

      mix droid.smoke "Say hello"
      mix droid.smoke "Summarize this repo" --cwd /path --timeout 30000
      mix droid.smoke "Create a test file" --auto high --model claude-3-5-sonnet-20241022
  """

  @shortdoc "Run a minimal Droid smoke prompt"

  use Mix.Task

  @switches [
    cwd: :string,
    timeout: :integer,
    auto: :string,
    model: :string
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)
    validate_options!(invalid)

    prompt =
      case positional do
        [value] -> value
        _ -> Mix.raise("expected exactly one PROMPT argument")
      end

    run_opts =
      []
      |> maybe_put(:cwd, opts[:cwd])
      |> maybe_put(:timeout_ms, opts[:timeout])
      |> maybe_put(:model, opts[:model])
      |> maybe_put(:auto, opts[:auto])

    Mix.shell().info(["Running Droid smoke prompt: ", :cyan, inspect(prompt), :reset])

    case droid_module().run(prompt, run_opts) do
      {:ok, stream} ->
        events = stream |> Enum.take(10_000) |> Enum.to_list()
        count = length(events)

        # Show some sample events
        sample_count = min(5, count)
        sample_events = Enum.take(events, sample_count)

        Mix.shell().info([
          :green,
          "\nSmoke run completed successfully!",
          :reset,
          "\n",
          "Total events: ",
          Integer.to_string(count),
          "\n\n",
          "Sample events (first #{sample_count}):\n"
        ])

        Enum.each(sample_events, fn event ->
          Mix.shell().info([
            "  • ",
            :cyan,
            Atom.to_string(event.type),
            :reset,
            " - ",
            format_event_summary(event)
          ])
        end)

      {:error, reason} ->
        Mix.raise("Droid smoke run failed: #{format_error(reason)}")
    end
  end

  defp validate_options!([]), do: :ok

  defp validate_options!(invalid) do
    invalid_text =
      Enum.map_join(invalid, ", ", fn
        {name, nil} -> format_invalid_name(name)
        {name, value} -> "#{format_invalid_name(name)}=#{value}"
      end)

    Mix.raise("invalid options: #{invalid_text}")
  end

  defp format_invalid_name(name) when is_binary(name) do
    if String.starts_with?(name, "-"), do: name, else: "--#{name}"
  end

  defp format_invalid_name(name) when is_atom(name), do: "--#{name}"

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason), do: inspect(reason)

  defp format_event_summary(%{type: :system, payload: payload}) do
    model = Map.get(payload, "model", "unknown")
    session = Map.get(payload, "session_id", "unknown")
    "model: #{model}, session: #{session}"
  end

  defp format_event_summary(%{type: :text, payload: payload}) do
    text = Map.get(payload, "text", "")
    truncated = String.slice(text, 0, 50)
    if String.length(text) > 50, do: "#{truncated}...", else: truncated
  end

  defp format_event_summary(%{type: :tool_use, payload: payload}) do
    tool = Map.get(payload, "tool_name", "unknown")
    "tool: #{tool}"
  end

  defp format_event_summary(%{type: :tool_result, payload: payload}) do
    tool = Map.get(payload, "tool_name", "unknown")
    "tool: #{tool}"
  end

  defp format_event_summary(%{type: :completion, payload: payload}) do
    turns = Map.get(payload, "numTurns", 0)
    duration = Map.get(payload, "durationMs", 0)
    "turns: #{turns}, duration: #{duration}ms"
  end

  defp format_event_summary(%{type: :error, payload: payload}) do
    error = Map.get(payload, "error", "unknown error")
    String.slice(error, 0, 50)
  end

  defp format_event_summary(%{type: :thinking, payload: payload}) do
    content = Map.get(payload, "content", "")
    truncated = String.slice(content, 0, 50)
    if String.length(content) > 50, do: "#{truncated}...", else: truncated
  end

  defp format_event_summary(%{payload: payload}) do
    inspect(payload) |> String.slice(0, 50)
  end

  defp droid_module do
    Application.get_env(:jido_droid, :droid_public_module, Jido.Droid)
  end
end
