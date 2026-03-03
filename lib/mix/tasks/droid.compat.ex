defmodule Mix.Tasks.Droid.Compat do
  @moduledoc """
  Validate whether the local Droid CLI is compatible with jido_droid.

      mix droid.compat
  """

  @shortdoc "Validate Droid CLI compatibility"

  use Mix.Task

  @impl true
  def run(_args) do
    case compatibility_module().check() do
      :ok ->
        case cli_info() do
          {:ok, program, version} when is_binary(version) ->
            Mix.shell().info([
              :green,
              "Droid compatibility check passed.",
              :reset,
              "\n",
              "CLI: ",
              program,
              "\n",
              "Version: ",
              version,
              "\n",
              "Required environment: FACTORY_API_KEY"
            ])

          {:ok, program, _} ->
            Mix.shell().info([
              :green,
              "Droid compatibility check passed.",
              :reset,
              "\n",
              "CLI: ",
              program,
              "\n",
              "Required environment: FACTORY_API_KEY"
            ])

          {:error, _} ->
            Mix.shell().info([
              :green,
              "Droid compatibility check passed.",
              :reset,
              "\n",
              "Required environment: FACTORY_API_KEY"
            ])
        end

      {:error, :cli_not_found} ->
        Mix.raise("""
        Droid compatibility check failed.

        Droid CLI not found in PATH.

        Install using:
          curl -fsSL https://app.factory.ai/cli | sh

        Or visit: https://docs.factory.ai/cli/droid-exec/overview
        """)

      {:error, :api_key_missing} ->
        Mix.raise("""
        Droid compatibility check failed.

        FACTORY_API_KEY environment variable is not set.

        Set your API key:
          export FACTORY_API_KEY=your_api_key_here

        Get your API key from: https://app.factory.ai/settings
        """)

      {:error, reason} ->
        Mix.raise("""
        Droid compatibility check failed.

        Reason: #{inspect(reason)}
        """)
    end
  end

  defp cli_info do
    with {:ok, program} <- cli_module().find_executable(),
         {:ok, version} <- cli_module().version() do
      {:ok, program, version}
    else
      {:ok, program} -> {:ok, program, nil}
      error -> error
    end
  end

  defp compatibility_module do
    Application.get_env(:jido_droid, :compatibility_module, Jido.Droid.Compatibility)
  end

  defp cli_module do
    Application.get_env(:jido_droid, :cli_module, Jido.Droid.CLI)
  end
end
