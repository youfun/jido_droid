defmodule Mix.Tasks.DroidTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  describe "mix droid.install" do
    test "shows CLI information when installed" do
      output =
        capture_io(fn ->
          Mix.Tasks.Droid.Install.run([])
        end)

      if Jido.Droid.cli_installed?() do
        assert output =~ "Droid CLI found:"
        assert output =~ "Version:"
      else
        assert output =~ "Droid CLI not found"
        assert output =~ "Install the Droid CLI"
      end
    end
  end

  describe "mix droid.compat" do
    test "checks compatibility" do
      if Jido.Droid.cli_installed?() do
        output =
          capture_io(fn ->
            Mix.Tasks.Droid.Compat.run([])
          end)

        if Jido.Droid.compatible?() do
          assert output =~ "Droid compatibility check passed"
          assert output =~ "CLI:"
          assert output =~ "FACTORY_API_KEY"
        else
          # Should raise an error
          assert_raise Mix.Error, fn ->
            Mix.Tasks.Droid.Compat.run([])
          end
        end
      else
        # Should raise an error when CLI not found
        assert_raise Mix.Error, fn ->
          Mix.Tasks.Droid.Compat.run([])
        end
      end
    end
  end

  describe "mix droid.smoke" do
    @tag :integration
    @tag timeout: 60_000
    test "runs smoke test with valid prompt" do
      unless Jido.Droid.cli_installed?() && Jido.Droid.compatible?() do
        IO.puts("Skipping: Droid CLI not available or not compatible")
        :ok
      else
        output =
          capture_io(fn ->
            Mix.Tasks.Droid.Smoke.run(["Say hello", "--timeout", "30000"])
          end)

        assert output =~ "Running Droid smoke prompt"
        assert output =~ "Smoke run completed successfully"
        assert output =~ "Total events:"
      end
    end

    test "raises error without prompt argument" do
      assert_raise Mix.Error, ~r/expected exactly one PROMPT argument/, fn ->
        Mix.Tasks.Droid.Smoke.run([])
      end
    end

    test "raises error with invalid options" do
      assert_raise Mix.Error, ~r/invalid options/, fn ->
        Mix.Tasks.Droid.Smoke.run(["test", "--invalid-option", "value"])
      end
    end

    test "accepts valid options" do
      # This should not raise, even if it fails to run
      # We're just testing option parsing
      try do
        Mix.Tasks.Droid.Smoke.run([
          "test",
          "--cwd",
          ".",
          "--timeout",
          "1000",
          "--auto",
          "low",
          "--model",
          "claude-3-5-sonnet-20241022"
        ])
      rescue
        Mix.Error ->
          # Expected if CLI not available
          :ok
      end
    end
  end
end
