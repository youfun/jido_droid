# Jido.Droid

Factory Droid CLI adapter for [Jido.Harness](https://github.com/agentjido/jido_harness).

## Status

⚠️ **Early development** — API is subject to change.

## Installation

Add `jido_droid` and `jido_harness` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_harness, "~> 0.1"},
    {:jido_droid, "~> 0.1"}
  ]
end
```

## Requirements

- Elixir `~> 1.18`
- Droid CLI installed and authenticated
- `FACTORY_API_KEY` environment variable set

## Quick Start

### 1) Install Droid CLI

```bash
curl -fsSL https://app.factory.ai/cli | sh
```

Or check if already installed:

```bash
mix droid.install
```

### 2) Set API Key

```bash
export FACTORY_API_KEY=your_api_key_here
```

### 3) Verify compatibility

```bash
mix droid.compat
```

### 4) Run a smoke test

```bash
mix droid.smoke "Say hello"
```

### 5) Use in your code

```elixir
{:ok, events} = Jido.Droid.run("Analyze this codebase")

events
|> Enum.each(&IO.inspect/1)
```

## Mix Tasks

### mix droid.install

Check if Droid CLI is installed and provide installation instructions:

```bash
mix droid.install
```

### mix droid.compat

Validate Droid CLI compatibility and environment setup:

```bash
mix droid.compat
```

### mix droid.smoke

Run a minimal smoke test to verify everything works:

```bash
mix droid.smoke "Say hello"
mix droid.smoke "Summarize this repo" --cwd /path --timeout 30000
mix droid.smoke "Create a test file" --auto high --model claude-3-5-sonnet-20241022
```

Options:
- `--cwd` - Working directory
- `--timeout` - Timeout in milliseconds
- `--auto` - Automation level (low, medium, high)
- `--model` - Model to use

## Usage

### Basic Run

```elixir
{:ok, events} = Jido.Droid.run("Fix the failing tests", cwd: "/path/to/project")
```

### With Options

```elixir
{:ok, events} = Jido.Droid.run("Refactor this module", 
  cwd: "/path/to/project",
  model: "claude-3-5-sonnet-20241022",
  auto: "high",
  allowed_tools: ["Read", "Edit", "Bash"]
)
```

### Using RunRequest

```elixir
alias Jido.Harness.RunRequest

request = RunRequest.new!(%{
  prompt: "Add tests for the user module",
  cwd: "/path/to/project",
  model: "claude-3-5-sonnet-20241022",
  metadata: %{
    "session_id" => "my-session-123",
    "reasoning_effort" => "high"
  }
})

{:ok, events} = Jido.Droid.run_request(request)
```

## Event Types

Droid emits the following normalized event types:

| Event Type | Description |
|------------|-------------|
| `:system` | Session initialization with model info |
| `:user_message` | User prompt |
| `:assistant_message` | Droid's text response |
| `:tool_use` | Droid is calling a tool |
| `:tool_result` | Tool execution result |
| `:result` | Session completed |

## Metadata Options

The `metadata` field in `RunRequest` supports Droid-specific options:

```elixir
metadata: %{
  "session_id" => "custom-session-id",
  "reasoning_effort" => "low" | "medium" | "high",
  "disabled_tools" => "ToolA,ToolB",
  "spec_model" => "claude-3-5-sonnet-20241022",
  "use_spec" => true
}
```

## Runtime Tooling

Use the built-in tasks to validate local CLI readiness:

```bash
mix droid.install
mix droid.compat
mix droid.smoke "Say hello"
```

## Public API

- `Jido.Droid.run/2` - Build a `RunRequest` from prompt + opts, then run
- `Jido.Droid.run_request/2` - Run a pre-built `%RunRequest{}`
- `Jido.Droid.cancel/1` - Cancel active run (not supported, returns error)
- `Jido.Droid.cli_installed?/0` - Check if Droid CLI is installed
- `Jido.Droid.compatible?/0` - Check if Droid CLI is compatible
- `Jido.Droid.assert_compatible!/0` - Raise if not compatible
- `Jido.Droid.version/0` - Get package version

## Development

```bash
mix deps.get
mix test
mix quality
```

## License

Apache-2.0. See [LICENSE](LICENSE) for details.

## Package Purpose

`jido_droid` is the Factory Droid CLI adapter for `jido_harness`, providing normalized request/event handling and runtime compatibility checks.

## Testing Paths

- Unit/contract tests: `mix test`
- Full quality gate: `mix quality`
- Optional live checks: `mix droid.install && mix droid.compat`
