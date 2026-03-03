defmodule Jido.Droid.ErrorTest do
  use ExUnit.Case, async: true

  alias Jido.Droid.Error

  describe "validation_error/2" do
    test "creates InvalidInputError" do
      error = Error.validation_error("test message", %{field: :test})
      assert %Error.InvalidInputError{} = error
      assert error.message == "test message"
      assert error.field == :test
    end

    test "works with empty context" do
      error = Error.validation_error("test")
      assert %Error.InvalidInputError{} = error
      assert error.message == "test"
    end
  end

  describe "execution_error/2" do
    test "creates ExecutionFailureError" do
      error = Error.execution_error("exec failed", %{code: 1})
      assert %Error.ExecutionFailureError{} = error
      assert error.message == "exec failed"
      assert error.details == %{code: 1}
    end
  end

  describe "config_error/2" do
    test "creates ConfigError" do
      error = Error.config_error("bad config", %{key: :value})
      assert %Error.ConfigError{} = error
      assert error.message == "bad config"
      assert error.key == :value
    end
  end
end
