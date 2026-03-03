defmodule Jido.Droid.Adapter do
  @moduledoc """
  `Jido.Harness.Adapter` implementation for Factory Droid CLI.

  Invokes `droid exec` with `--output-format stream-json` and normalizes
  the JSONL event stream into `Jido.Harness.Event` structs.
  """

  @behaviour Jido.Harness.Adapter

  alias Jido.Droid.{CLI, Compatibility, Error, Stream}
  alias Jido.Harness.{Capabilities, RunRequest, RuntimeContract}

  @impl true
  @spec id() :: atom()
  def id, do: :droid

  @impl true
  @spec capabilities() :: Capabilities.t()
  def capabilities do
    %Capabilities{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: true,
      resume?: true,
      usage?: true,
      file_changes?: true,
      cancellation?: false
    }
  end

  @impl true
  @spec runtime_contract() :: RuntimeContract.t()
  def runtime_contract do
    RuntimeContract.new!(%{
      provider: :droid,
      host_env_required_any: ["FACTORY_API_KEY"],
      host_env_required_all: [],
      sprite_env_forward: ["FACTORY_API_KEY"],
      sprite_env_injected: %{},
      runtime_tools_required: ["droid"],
      compatibility_probes: [
        %{
          "name" => "droid_version",
          "command" => "droid --version",
          "expect_all" => ["."]
        }
      ],
      install_steps: [
        %{
          "tool" => "droid",
          "when_missing" => true,
          "command" => "curl -fsSL https://app.factory.ai/cli | sh"
        }
      ],
      auth_bootstrap_steps: [],
      triage_command_template: "droid exec --output-format stream-json \"$(cat {{prompt_file}})\"",
      coding_command_template: "droid exec --output-format stream-json --auto medium \"$(cat {{prompt_file}})\"",
      success_markers: [
        %{"type" => "completion"}
      ]
    })
  end

  @impl true
  @spec run(RunRequest.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(%RunRequest{} = request, opts \\ []) when is_list(opts) do
    with :ok <- compatibility_module().check(),
         {:ok, droid_path} <- cli_module().find_executable() do
      args = build_args(request, opts)
      stream = stream_module().build(droid_path, args, request)
      {:ok, stream}
    end
  rescue
    e in [ArgumentError] ->
      {:error, Error.validation_error("Invalid run request", %{details: Exception.message(e)})}
  end

  @impl true
  @spec cancel(String.t()) :: :ok | {:error, term()}
  def cancel(_session_id) do
    # Droid exec processes are cancelled by killing the OS process.
    # Session-level cancellation is not exposed via CLI.
    {:error, :not_supported}
  end

  # -- Command building --

  defp build_args(%RunRequest{} = req, opts) do
    auto = Keyword.get(opts, :auto, "medium")

    ["exec", "--output-format", "stream-json"]
    |> maybe_add("--auto", auto)
    |> maybe_add("--model", req.model)
    |> maybe_add("--cwd", req.cwd)
    |> maybe_add("--session-id", meta(req, "session_id"))
    |> maybe_add("--reasoning-effort", meta(req, "reasoning_effort"))
    |> maybe_add("--enabled-tools", tools_csv(req.allowed_tools))
    |> maybe_add("--disabled-tools", meta(req, "disabled_tools"))
    |> maybe_add("--spec-model", meta(req, "spec_model"))
    |> maybe_flag("--use-spec", meta(req, "use_spec"))
    |> Kernel.++([req.prompt])
  end

  defp maybe_add(args, _flag, nil), do: args
  defp maybe_add(args, _flag, ""), do: args
  defp maybe_add(args, flag, value), do: args ++ [flag, to_string(value)]

  defp maybe_flag(args, _flag, nil), do: args
  defp maybe_flag(args, _flag, false), do: args
  defp maybe_flag(args, flag, _), do: args ++ [flag]

  defp meta(%RunRequest{metadata: m}, key) when is_map(m), do: Map.get(m, key)
  defp meta(_, _), do: nil

  defp tools_csv(nil), do: nil
  defp tools_csv([]), do: nil
  defp tools_csv(tools) when is_list(tools), do: Enum.join(tools, ",")

  # -- Module injection points for testing --

  defp compatibility_module do
    Application.get_env(:jido_droid, :compatibility_module, Compatibility)
  end

  defp cli_module do
    Application.get_env(:jido_droid, :cli_module, CLI)
  end

  defp stream_module do
    Application.get_env(:jido_droid, :stream_module, Stream)
  end


end
