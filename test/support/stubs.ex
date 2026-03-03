defmodule Jido.Droid.Test.StubCLI do
  @moduledoc """
  Stub implementation of CLI module for testing.
  """

  def find_executable do
    {:ok, "/usr/local/bin/droid"}
  end

  def version do
    {:ok, "1.0.0"}
  end
end

defmodule Jido.Droid.Test.StubCLINotFound do
  @moduledoc """
  Stub that simulates CLI not found.
  """

  def find_executable do
    {:error, :not_found}
  end

  def version do
    {:error, :not_found}
  end
end

defmodule Jido.Droid.Test.StubCompatibility do
  @moduledoc """
  Stub implementation of Compatibility module for testing.
  """

  def check do
    :ok
  end

  def check! do
    :ok
  end
end

defmodule Jido.Droid.Test.StubCompatibilityFailed do
  @moduledoc """
  Stub that simulates compatibility check failure.
  """

  def check do
    {:error, :incompatible}
  end

  def check! do
    raise Jido.Droid.Error.ConfigError, message: "Compatibility check failed"
  end
end

defmodule Jido.Droid.Test.StubStream do
  @moduledoc """
  Stub implementation of Stream module for testing.
  """
  alias Jido.Droid.Test.Fixtures

  def build(_executable, _args, _request) do
    # Return a stream of sample events
    [
      Fixtures.system_event(),
      Fixtures.text_event(),
      Fixtures.tool_use_event(),
      Fixtures.tool_result_event(),
      Fixtures.completion_event()
    ]
    |> Stream.map(&Jido.Droid.Mapper.map_event/1)
  end
end

defmodule Jido.Droid.Test.StubStreamError do
  @moduledoc """
  Stub that simulates stream errors.
  """

  def build(_executable, _args, _request) do
    Stream.resource(
      fn -> :ok end,
      fn _ ->
        raise RuntimeError, "Stream error"
      end,
      fn _ -> :ok end
    )
  end
end

defmodule Jido.Droid.Test.StubMapper do
  @moduledoc """
  Stub implementation of Mapper module for testing.
  """

  def map_event(event) do
    %Jido.Harness.Event{
      provider: :droid,
      type: :test,
      payload: event,
      timestamp: DateTime.utc_now()
    }
  end
end
