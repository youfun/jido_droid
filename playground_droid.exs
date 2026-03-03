Mix.install([
  {:jido_droid, path: ".", force: true},
  {:phoenix_playground, "~> 0.1.8"},
  {:jason, "~> 1.4"}
])

# Ensure Droid CLI is available
unless Jido.Droid.cli_installed?() do
  IO.puts("\n⚠️  WARNING: Droid CLI not found in PATH")
  IO.puts("Install with: curl -fsSL https://app.factory.ai/cli | sh\n")
end

# Check API key
unless System.get_env("FACTORY_API_KEY") do
  IO.puts("\n⚠️  WARNING: FACTORY_API_KEY environment variable not set")
  IO.puts("Set with: export FACTORY_API_KEY=your_key_here\n")
end

defmodule DroidPlaygroundLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    cli_installed = Jido.Droid.cli_installed?()
    compatible = if cli_installed, do: Jido.Droid.compatible?(), else: false
    api_key_set = System.get_env("FACTORY_API_KEY") not in [nil, ""]

    {:ok,
     assign(socket,
       cli_installed: cli_installed,
       compatible: compatible,
       api_key_set: api_key_set,
       prompt: "List the files in the current directory and briefly describe the project structure.",
       auto_level: "low",
       model: "",
       reasoning_effort: "(default)",
       cwd: File.cwd!(),
       use_spec: false,
       enabled_tools: "",
       disabled_tools: "",
       running: false,
       events: [],
       raw_output: "",
       exit_code: nil,
       error: nil,
       history: []
     )}
  end

  def render(assigns) do
    ~H"""
    <script src="https://cdn.tailwindcss.com"></script>
    <div class="min-h-screen bg-gray-50 py-6 px-4 font-sans">
      <div class="max-w-7xl mx-auto">

        <div class="bg-gradient-to-r from-violet-600 to-indigo-600 rounded-xl px-6 py-4 mb-6 shadow-lg">
          <h1 class="text-2xl font-bold text-white">Jido.Droid Playground</h1>
          <p class="text-violet-100 text-sm mt-1">
            Testing Jido.Droid.run(prompt, opts) → stream events
          </p>
          <div class="flex gap-4 mt-2 text-xs">
            <span class={if(@cli_installed, do: "text-green-300", else: "text-red-300")}>
              Droid CLI: {if(@cli_installed, do: "installed", else: "NOT FOUND")}
            </span>
            <span class={if(@compatible, do: "text-green-300", else: "text-yellow-300")}>
              Compatible: {if(@compatible, do: "yes", else: if(@cli_installed, do: "check failed", else: "n/a"))}
            </span>
            <span class={if(@api_key_set, do: "text-green-300", else: "text-yellow-300")}>
              Auth: {if(@api_key_set, do: "API key", else: "CLI auth")}
            </span>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

          <div class="lg:col-span-5 space-y-4">
            <form phx-change="validate" phx-submit="run_droid" class="space-y-4">

              <div class="bg-white p-4 rounded-lg border shadow-sm">
                <label class="block text-sm font-semibold text-gray-700 mb-2">Prompt</label>
                <textarea
                  name="prompt"
                  rows="4"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm font-mono focus:ring-indigo-500 focus:border-indigo-500"
                >{@prompt}</textarea>
              </div>

              <div class="bg-white p-4 rounded-lg border shadow-sm space-y-3">
                <label class="block text-sm font-semibold text-gray-700">Droid Options</label>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase">Autonomy (--auto)</label>
                    <select name="auto_level" class="mt-1 w-full px-3 py-2 border rounded-md text-sm">
                      <option value="(none)" selected={@auto_level == "(none)"}>(none) read-only</option>
                      <option value="low" selected={@auto_level == "low"}>low</option>
                      <option value="medium" selected={@auto_level == "medium"}>medium</option>
                      <option value="high" selected={@auto_level == "high"}>high</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase">Reasoning Effort</label>
                    <select name="reasoning_effort" class="mt-1 w-full px-3 py-2 border rounded-md text-sm">
                      <option :for={level <- ["(default)", "off", "none", "low", "medium", "high", "max"]}
                        value={level} selected={@reasoning_effort == level}>{level}</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label class="block text-xs font-medium text-gray-500 uppercase">Model (blank = default)</label>
                  <input type="text" name="model" value={@model}
                    class="mt-1 w-full px-3 py-2 border rounded-md text-sm font-mono"
                    placeholder="e.g. claude-sonnet-4-5-20250929" />
                </div>

                <div>
                  <label class="block text-xs font-medium text-gray-500 uppercase">Working Directory (cwd)</label>
                  <input type="text" name="cwd" value={@cwd}
                    class="mt-1 w-full px-3 py-2 border rounded-md text-sm font-mono" />
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase">Enabled Tools</label>
                    <input type="text" name="enabled_tools" value={@enabled_tools}
                      class="mt-1 w-full px-3 py-2 border rounded-md text-sm font-mono"
                      placeholder="Read,Grep" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-gray-500 uppercase">Disabled Tools</label>
                    <input type="text" name="disabled_tools" value={@disabled_tools}
                      class="mt-1 w-full px-3 py-2 border rounded-md text-sm font-mono"
                      placeholder="Execute" />
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <input type="checkbox" name="use_spec" id="use_spec" value="true" checked={@use_spec}
                    class="rounded border-gray-300 text-indigo-600" />
                  <label for="use_spec" class="text-sm text-gray-700">Use Spec Mode</label>
                </div>
              </div>

              <div class="flex gap-3">
                <button type="submit" disabled={@running or not @cli_installed}
                  class={"flex-1 py-2.5 px-4 rounded-md text-sm font-semibold text-white shadow transition " <>
                    if(@running or not @cli_installed,
                      do: "bg-gray-400 cursor-not-allowed",
                      else: "bg-indigo-600 hover:bg-indigo-700")}>
                  {if(@running, do: "Running Jido.Droid.run(...)...", else: "Run Droid")}
                </button>

                <button type="button" phx-click="clear"
                  class="py-2.5 px-4 rounded-md text-sm font-semibold bg-white text-gray-700 border border-gray-300 shadow-sm hover:bg-gray-50">
                  Clear
                </button>
              </div>
            </form>

            <%!-- API Call Preview --%>
            <div class="bg-gray-900 rounded-lg p-3 text-xs font-mono text-green-400">
              <div class="text-gray-500 mb-1"># Equivalent Elixir code:</div>
              <div>Jido.Droid.run(prompt, [</div>
              <div class="pl-4">cwd: "{@cwd}",</div>
              <div :if={@model != ""} class="pl-4">model: "{@model}",</div>
              <div :if={@auto_level != "(none)"} class="pl-4">auto: "{@auto_level}",</div>
              <div>])</div>
            </div>

            <%!-- History --%>
            <div class="bg-white rounded-lg border shadow-sm">
              <div class="px-4 py-3 border-b bg-gray-50 flex justify-between items-center">
                <h3 class="text-sm font-semibold text-gray-700">History</h3>
                <span class="text-xs text-gray-500">{length(@history)} runs</span>
              </div>
              <div class="max-h-64 overflow-y-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                      <th class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Prompt</th>
                      <th class="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Status</th>
                      <th class="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase">Events</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-200">
                    <tr :for={item <- @history} class="hover:bg-gray-50 cursor-pointer"
                        phx-click="load_history" phx-value-idx={item.idx}>
                      <td class="px-3 py-2 text-xs text-gray-500 whitespace-nowrap">{Calendar.strftime(item.time, "%H:%M:%S")}</td>
                      <td class="px-3 py-2 text-xs text-gray-900 truncate max-w-[150px]">{String.slice(item.prompt, 0..40)}</td>
                      <td class="px-3 py-2 text-xs text-center">
                        <span class={"inline-block px-1.5 py-0.5 rounded text-xs font-mono " <>
                          if(item.success, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")}>
                          {if(item.success, do: "ok", else: "err")}
                        </span>
                      </td>
                      <td class="px-3 py-2 text-xs text-center text-gray-500">{item.event_count}</td>
                    </tr>
                    <tr :if={@history == []}>
                      <td colspan="4" class="px-3 py-6 text-center text-xs text-gray-400 italic">No runs yet</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <%!-- Right: Output --%>
          <div class="lg:col-span-7 space-y-4">

            <div :if={@error} class="bg-red-50 border border-red-200 rounded-lg p-4">
              <p class="text-sm text-red-700 font-semibold">Error from Jido.Droid</p>
              <pre class="text-xs text-red-600 font-mono mt-1 whitespace-pre-wrap">{@error}</pre>
            </div>

            <div :if={@exit_code != nil}
              class={"rounded-lg px-4 py-2 text-sm font-semibold " <>
                if(@exit_code == :ok,
                  do: "bg-green-100 text-green-800 border border-green-200",
                  else: "bg-red-100 text-red-800 border border-red-200")}>
              Status: {@exit_code} | Events: {length(@events)}
            </div>

            <div class="bg-white rounded-lg border shadow-sm">
              <div class="px-4 py-3 border-b bg-gray-50">
                <h2 class="text-sm font-semibold text-gray-700">Jido.Droid Event stream</h2>
              </div>
              <div class="p-4 max-h-[500px] overflow-y-auto space-y-2">
                <p :if={@events == []} class="text-sm text-gray-400 italic text-center py-8">
                  Click "Run Droid" to see normalized events
                </p>
                <div :for={{event, idx} <- Enum.with_index(@events)}
                  class={"rounded-md border p-3 text-xs " <> event_color(event)}>
                  <div class="flex justify-between items-center mb-1">
                    <span class="font-semibold">
                      #{idx + 1} | type: {event.type}
                      | provider: {event.provider}
                    </span>
                    <span :if={event.session_id} class="text-gray-400 font-mono text-[10px]">
                      {String.slice(to_string(event.session_id), 0..12)}...
                    </span>
                  </div>
                  {render_event_body(assigns, event)}
                </div>
              </div>
            </div>

            <%!-- Raw payload details --%>
            <details :if={@events != []} class="bg-white rounded-lg border shadow-sm">
              <summary class="px-4 py-3 text-sm font-semibold text-gray-700 cursor-pointer hover:bg-gray-50">
                Raw Event Payloads ({length(@events)} events)
              </summary>
              <pre class="p-4 text-xs font-mono bg-gray-900 text-green-400 rounded-b-lg overflow-x-auto max-h-64 overflow-y-auto">{@raw_output}</pre>
            </details>

          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_event_body(assigns, %{type: type, payload: payload} = event) do
    assigns = assign(assigns, type: type, payload: payload, event: event)

    ~H"""
    <div class="mt-1">
      <%= cond do %>
        <% @type in [:user_message, :assistant_message] -> %>
          <pre class="whitespace-pre-wrap text-gray-700 bg-white/50 p-2 rounded">{String.slice(Map.get(@payload, "text", ""), 0..800)}</pre>
        <% @type == :tool_use -> %>
          <div class="font-mono text-gray-600">
            <span class="bg-amber-200 px-1 rounded">{Map.get(@payload, "tool_name", "?")}</span>
          </div>
          <pre class="whitespace-pre-wrap text-gray-600 mt-1 bg-white/50 p-2 rounded text-[11px]">{Jason.encode!(Map.get(@payload, "parameters", %{}), pretty: true) |> String.slice(0..500)}</pre>
        <% @type == :tool_result -> %>
          <span class={if(Map.get(@payload, "is_error"), do: "text-red-600", else: "text-green-700")}>
            {if(Map.get(@payload, "is_error"), do: "ERROR", else: "OK")}
          </span>
          <pre class="whitespace-pre-wrap text-gray-600 mt-1 bg-white/50 p-2 rounded text-[11px]">{String.slice(to_string(Map.get(@payload, "value", "")), 0..600)}</pre>
        <% @type == :result -> %>
          <div class="text-gray-500 text-[11px]">
            turns: {Map.get(@payload, "num_turns")} | duration: {Map.get(@payload, "duration_ms")}ms
          </div>
          <pre class="whitespace-pre-wrap text-gray-700 bg-white/50 p-2 rounded mt-1">{String.slice(Map.get(@payload, "final_text", ""), 0..1000)}</pre>
        <% @type == :system -> %>
          <div class="text-gray-500">
            model: {Map.get(@payload, "model", "?")} |
            tools: {length(Map.get(@payload, "tools", []))}
          </div>
        <% true -> %>
          <details>
            <summary class="text-gray-500 cursor-pointer">payload</summary>
            <pre class="mt-1 text-[11px] font-mono text-gray-600 bg-white/50 p-2 rounded overflow-x-auto">{Jason.encode!(@payload, pretty: true) |> String.slice(0..600)}</pre>
          </details>
      <% end %>
    </div>
    """
  end

  defp event_color(%{type: :system}), do: "bg-blue-50 border-blue-200"
  defp event_color(%{type: :user_message}), do: "bg-gray-50 border-gray-200"
  defp event_color(%{type: :assistant_message}), do: "bg-indigo-50 border-indigo-200"
  defp event_color(%{type: :tool_use}), do: "bg-amber-50 border-amber-200"
  defp event_color(%{type: :tool_result}), do: "bg-emerald-50 border-emerald-200"
  defp event_color(%{type: :result}), do: "bg-violet-50 border-violet-200"
  defp event_color(_), do: "bg-gray-50 border-gray-200"

  def handle_event("validate", params, socket) do
    {:noreply,
     assign(socket,
       prompt: params["prompt"] || socket.assigns.prompt,
       auto_level: params["auto_level"] || socket.assigns.auto_level,
       model: params["model"] || socket.assigns.model,
       reasoning_effort: params["reasoning_effort"] || socket.assigns.reasoning_effort,
       cwd: params["cwd"] || socket.assigns.cwd,
       use_spec: params["use_spec"] == "true",
       enabled_tools: params["enabled_tools"] || socket.assigns.enabled_tools,
       disabled_tools: params["disabled_tools"] || socket.assigns.disabled_tools
     )}
  end

  def handle_event("run_droid", _params, socket) do
    if socket.assigns.running do
      {:noreply, socket}
    else
      prompt = String.trim(socket.assigns.prompt)

      if prompt == "" do
        {:noreply, assign(socket, error: "Prompt cannot be empty")}
      else
        opts = build_droid_opts(socket.assigns)
        parent = self()

        Task.start(fn ->
          result =
            try do
              case Jido.Droid.run(prompt, opts) do
                {:ok, stream} ->
                  events = Enum.to_list(stream)
                  {:ok, events}

                {:error, reason} ->
                  {:error, inspect(reason, pretty: true)}
              end
            rescue
              e ->
                {:error, Exception.message(e) <> "\n\n" <> Exception.format_stacktrace(__STACKTRACE__)}
            end

          send(parent, {:droid_result, result, prompt})
        end)

        {:noreply,
         assign(socket,
           running: true,
           error: nil,
           events: [],
           raw_output: "",
           exit_code: nil
         )}
      end
    end
  end

  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, events: [], raw_output: "", exit_code: nil, error: nil)}
  end

  def handle_event("load_history", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)

    case Enum.find(socket.assigns.history, &(&1.idx == idx)) do
      nil ->
        {:noreply, socket}

      item ->
        {:noreply,
         assign(socket,
           events: item.events,
           raw_output: item.raw_output,
           exit_code: item.exit_code,
           error: nil
         )}
    end
  end

  def handle_info({:droid_result, result, prompt}, socket) do
    case result do
      {:ok, events} ->
        raw =
          events
          |> Enum.map(fn e -> inspect(e, pretty: true, limit: :infinity) end)
          |> Enum.join("\n\n")

        history_item = %{
          idx: length(socket.assigns.history),
          time: DateTime.utc_now(),
          prompt: prompt,
          success: true,
          event_count: length(events),
          events: events,
          raw_output: raw,
          exit_code: :ok
        }

        {:noreply,
         assign(socket,
           running: false,
           events: events,
           raw_output: raw,
           exit_code: :ok,
           error: nil,
           history: [history_item | socket.assigns.history]
         )}

      {:error, reason} ->
        history_item = %{
          idx: length(socket.assigns.history),
          time: DateTime.utc_now(),
          prompt: prompt,
          success: false,
          event_count: 0,
          events: [],
          raw_output: reason,
          exit_code: :error
        }

        {:noreply,
         assign(socket,
           running: false,
           events: [],
           raw_output: "",
           exit_code: :error,
           error: reason,
           history: [history_item | socket.assigns.history]
         )}
    end
  end

  defp build_droid_opts(assigns) do
    opts = [cwd: assigns.cwd]

    opts =
      if assigns.model != "" do
        Keyword.put(opts, :model, assigns.model)
      else
        opts
      end

    # Build metadata for droid-specific options
    meta = %{}

    meta =
      if assigns.reasoning_effort != "(default)" do
        Map.put(meta, "reasoning_effort", assigns.reasoning_effort)
      else
        meta
      end

    meta =
      if assigns.use_spec do
        Map.put(meta, "use_spec", true)
      else
        meta
      end

    meta =
      if assigns.disabled_tools != "" do
        Map.put(meta, "disabled_tools", assigns.disabled_tools)
      else
        meta
      end

    opts =
      if meta != %{} do
        Keyword.put(opts, :metadata, meta)
      else
        opts
      end

    # allowed_tools maps to --enabled-tools
    opts =
      if assigns.enabled_tools != "" do
        tools = String.split(assigns.enabled_tools, ",", trim: true)
        Keyword.put(opts, :allowed_tools, tools)
      else
        opts
      end

    # auto level passed as adapter opt
    auto =
      case assigns.auto_level do
        "(none)" -> nil
        level -> level
      end

    if auto, do: Keyword.put(opts, :auto, auto), else: opts
  end
end

defmodule DroidPlaygroundRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {PhoenixPlayground.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)
    live("/", DroidPlaygroundLive)
  end
end

IO.puts("""

  =============================================
  Jido.Droid Playground
  =============================================

  Droid CLI installed: #{Jido.Droid.cli_installed?()}
  Compatible:          #{if Jido.Droid.cli_installed?(), do: Jido.Droid.compatible?(), else: "n/a"}
  API Key set:         #{System.get_env("FACTORY_API_KEY") not in [nil, ""]} (optional)

  Open http://localhost:5006 in your browser.
  Press Ctrl+C twice to stop.
  =============================================
""")

PhoenixPlayground.start(
  plug: DroidPlaygroundRouter,
  port: 5006,
  ip: {0, 0, 0, 0},
  endpoint_options: [
    secret_key_base: :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false)
  ]
)
