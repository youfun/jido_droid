defmodule Jido.Droid.CLI do
  @moduledoc """
  Droid CLI discovery and validation.
  """

  @doc """
  Finds the droid executable in PATH.
  """
  @spec find_executable() :: {:ok, String.t()} | {:error, term()}
  def find_executable do
    case System.find_executable("droid") do
      nil ->
        {:error,
         Jido.Droid.Error.execution_error(
           "droid CLI not found in PATH. Install: curl -fsSL https://app.factory.ai/cli | sh",
           %{provider: :droid}
         )}

      path ->
        {:ok, path}
    end
  end

  @doc """
  Returns true if droid CLI is in PATH.
  """
  @spec installed?() :: boolean()
  def installed? do
    case find_executable() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Gets the version of the droid CLI.
  """
  @spec version() :: {:ok, String.t()} | {:error, term()}
  def version do
    case find_executable() do
      {:ok, droid_path} ->
        case System.cmd(droid_path, ["--version"], stderr_to_stdout: true) do
          {output, 0} ->
            version = String.trim(output)
            {:ok, version}

          {output, _code} ->
            {:error,
             Jido.Droid.Error.execution_error(
               "Failed to get droid version: #{output}",
               %{provider: :droid}
             )}
        end

      error ->
        error
    end
  end
end
