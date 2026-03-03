defmodule Jido.Droid.Compatibility do
  @moduledoc """
  Droid CLI compatibility checks.
  """

  alias Jido.Droid.{CLI, Error}

  @doc """
  Returns true if Droid CLI is installed.
  """
  @spec cli_installed?() :: boolean()
  def cli_installed?, do: CLI.installed?()

  @doc """
  Returns true if Droid CLI is compatible.
  """
  @spec compatible?() :: boolean()
  def compatible? do
    case check() do
      :ok -> true
      {:error, _} -> false
    end
  end

  @doc """
  Checks Droid CLI compatibility.
  """
  @spec check() :: :ok | {:error, term()}
  def check do
    with {:ok, _path} <- CLI.find_executable() do
      :ok
    end
  end

  @doc """
  Raises if Droid CLI is not compatible.
  """
  @spec assert_compatible!() :: :ok | no_return()
  def assert_compatible! do
    case check() do
      :ok ->
        :ok

      {:error, error} ->
        raise Error.ConfigError,
          message: "Droid CLI compatibility check failed",
          key: :droid_cli,
          value: inspect(error)
    end
  end
end
