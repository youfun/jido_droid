defmodule Mix.Tasks.Droid.Install do
  @moduledoc """
  Check for the Droid CLI and provide installation instructions.

      mix droid.install
  """

  @shortdoc "Check Droid CLI installation and provide setup instructions"

  use Mix.Task

  @impl true
  def run(_args) do
    case cli_module().find_executable() do
      {:ok, program} ->
        case cli_module().version() do
          {:ok, version} ->
            Mix.shell().info([
              "Droid CLI found: ",
              :green,
              program,
              :reset,
              "\n",
              "Version: ",
              version
            ])

          {:error, _} ->
            Mix.shell().info([
              "Droid CLI found: ",
              :green,
              program,
              :reset,
              "\n",
              :yellow,
              "Warning: Could not determine version",
              :reset
            ])
        end

      {:error, :not_found} ->
        Mix.shell().info([
          :yellow,
          "Droid CLI not found.",
          :reset,
          "\n\n",
          "Install the Droid CLI using:\n\n",
          "  curl -fsSL https://app.factory.ai/cli | sh\n\n",
          "Or visit: https://docs.factory.ai/cli/droid-exec/overview\n\n",
          "After installation, run this task again to verify:\n\n",
          "  mix droid.install\n"
        ])
    end
  end

  defp cli_module do
    Application.get_env(:jido_droid, :cli_module, Jido.Droid.CLI)
  end
end
