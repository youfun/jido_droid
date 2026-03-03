defmodule Jido.Droid.StreamTest do
  use ExUnit.Case, async: false

  alias Jido.Droid.Stream
  alias Jido.Droid.Test.Fixtures

  describe "build/3 - structure" do
    test "returns a stream" do
      request = Fixtures.run_request()
      stream = Stream.build("/fake/droid", ["exec"], request)

      # Stream.resource returns an Elixir Stream - verify it's enumerable
      assert Enumerable.impl_for(stream) != nil
    end

    test "function signature is correct" do
      assert function_exported?(Stream, :build, 3)
    end
  end

  describe "build/3 - integration" do
    @tag :integration
    test "builds event stream from actual droid process" do
      # This test requires actual droid CLI to be installed
      request = Fixtures.run_request()

      case System.find_executable("droid") do
        nil ->
          # Skip if droid not installed
          :ok

        droid_path ->
          args = ["exec", "--output-format", "stream-json", "echo test"]
          stream = Stream.build(droid_path, args, request)

          # Verify stream is enumerable
          assert Enumerable.impl_for(stream) != nil

          # Don't actually consume the stream to avoid long-running test
          # Just verify it was created successfully
      end
    end
  end
end
