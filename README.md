# Jido.Droid

`Jido.Droid` is the Factory Droid CLI adapter for [Jido.Harness](https://github.com/agentjido/jido_harness).

It provides:
- `Jido.Harness.Adapter` implementation (`Jido.Droid.Adapter`)
- Normalized streaming event mapping (`Jido.Droid.Mapper`)
- Port-based CLI communication with JSONL stream parsing
- Compatibility/install/smoke mix tasks
- Full integration with Jido ecosystem
- Runtime compatibility checks and diagnostics



## Installation

Add `jido_droid` and `jido_harness` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_harness, "~> 0.1"},
    {:jido_droid, github: "youfun/jido_droid"}
  ]
end
```

**Note**: `jido_droid` is not yet published to Hex. Use the GitHub dependency until the first release.

## Requirements

- Elixir `~> 1.18`
- Droid CLI installed and authenticated (via CLI login or `FACTORY_API_KEY` environment variable)

## Quick Start

### 1) Install Droid CLI

```bash
curl -fsSL https://app.factory.ai/cli | sh
```

Or check if already installed:

```bash
mix droid.install
```

### 2) Authenticate

**Option A: Use Droid CLI authentication (recommended)**
```bash
droid  # Follow the login prompts
```

**Option B: Set API key directly**
```bash
export FACTORY_API_KEY=your_api_key_here
```

Get your API key from: https://app.factory.ai/settings

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
mix droid.smoke "Create a test file" --auto high --model gemini-3-flash-preview
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
  model: "gemini-3-flash-preview",
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
  model: "gemini-3-flash-preview",
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

## Event Mapping

Droid stream events are normalized to `Jido.Harness.Event` with:
- `provider: :droid`
- ISO-8601 `timestamp` (when available)
- Raw event passthrough in `raw` field
- Standardized `payload` structure

Canonical event types include:
- `:system` - Session initialization with model info
- `:user_message` - User prompt
- `:assistant_message` - AI response text
- `:tool_use` - Tool invocation by Droid
- `:tool_result` - Tool execution result
- `:result` - Session completion

Example event structure:
```elixir
%Jido.Harness.Event{
  provider: :droid,
  type: :assistant_message,
  session_id: "bee5e827-a0b5-44cb-a82f-25c3833ac734",
  timestamp: ~U[2026-03-03 11:12:22.695Z],
  payload: %{
    "id" => "e6db5bdc-ed6e-491c-aacd-6f45a280ecf5",
    "role" => "assistant",
    "text" => "Hello!"
  },
  raw: %{...}  # Original Droid CLI event
}
```

## Metadata Contract

`Jido.Droid.Adapter` reads provider-specific runtime controls from `request.metadata`.

Supported keys:
- `"session_id"` - Custom session identifier (string)
- `"reasoning_effort"` - Reasoning level: `"low"` | `"medium"` | `"high"`
- `"disabled_tools"` - Comma-separated tool names to disable (string)
- `"spec_model"` - Model to use for spec mode (string)
- `"use_spec"` - Enable spec mode (boolean)

Precedence order:
1. Runtime adapter options
2. Metadata values
3. Defaults derived from `RunRequest`

Default mapping from `RunRequest`:
- `prompt` → CLI prompt argument
- `cwd` → working directory
- `model` → `--model` flag
- `timeout_ms` → process timeout
- `allowed_tools` → `--enabled-tools` flag

Example:
```elixir
metadata: %{
  "session_id" => "custom-session-id",
  "reasoning_effort" => "high",
  "disabled_tools" => "ToolA,ToolB",
  "spec_model" => "gemini-3-flash-preview",
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

### Interactive Playground

The project includes an interactive web-based playground for testing and exploring Jido.Droid:

```bash
elixir playground_droid.exs
```

Then open http://localhost:5006 in your browser.

**Features:**
- Live event stream visualization
- Configure all Droid options (model, auto level, reasoning effort, tools)
- View normalized `Jido.Harness.Event` structures
- Inspect raw Droid CLI events
- Session history tracking
- Real-time tool call monitoring

The playground demonstrates:
- How Droid CLI JSONL events are normalized to Harness events
- Event types: `:system`, `:user_message`, `:assistant_message`, `:tool_use`, `:tool_result`, `:result`
- Timestamp conversion (milliseconds → ISO-8601)
- Payload standardization and field mapping
- Session ID consistency across events

Perfect for understanding the event flow and testing different configurations before integrating into your application.

### Integration Tests

Integration tests are opt-in and excluded by default (`@tag :integration`).

To run integration tests:
```bash
mix test --include integration
```

**Note**: Integration tests require:
- Droid CLI installed
- Authenticated (via CLI login or `FACTORY_API_KEY`)
- Will consume API credits

## Limitations

- **No cancellation support** - Droid CLI does not support session-level cancellation. The `cancel/1` function returns `{:error, :not_supported}`. To stop a running Droid process, you must terminate the OS process directly.
- **CLI dependency** - Requires Droid CLI to be installed and in PATH
- **Authentication required** - Must authenticate via Droid CLI login or `FACTORY_API_KEY` environment variable
- **Network required** - CLI communicates with Factory API
- **Process-based** - Each run spawns a new Droid CLI process

## Troubleshooting

### CLI not found
```bash
# Check if droid is in PATH
which droid  # Unix/Mac
where droid  # Windows

# Install Droid CLI
curl -fsSL https://app.factory.ai/cli | sh
```

### Authentication issues

**Check authentication status:**
```bash
droid --version  # Should work if authenticated
```

**Option 1: Use Droid CLI login (recommended)**
```bash
droid  # Follow login prompts
```

**Option 2: Use API key**
```bash
# Check if API key is set
echo $FACTORY_API_KEY  # Unix/Mac
echo %FACTORY_API_KEY%  # Windows

# Set API key
export FACTORY_API_KEY=your_key_here  # Unix/Mac
set FACTORY_API_KEY=your_key_here     # Windows
```

Get your API key from: https://app.factory.ai/settings

### Compatibility issues
```bash
# Run diagnostics
mix droid.compat

# Check version
droid --version

# Verify installation
mix droid.install
```

### Stream parsing errors
If you encounter JSONL parsing errors:
- Ensure Droid CLI is up to date
- Check `mix droid.compat` for version compatibility
- Verify network connectivity to Factory API

### Timeout issues
If runs timeout frequently:
```elixir
# Increase timeout (default is 60000ms)
Jido.Droid.run("long task", timeout_ms: 300_000)
```

## License

Apache-2.0. See [LICENSE](LICENSE) for details.

## Package Purpose

`jido_droid` is the Factory Droid CLI adapter for `jido_harness`, providing normalized request/event handling and runtime compatibility checks.

## Testing Paths

- Unit/contract tests: `mix test`
- Full quality gate: `mix quality`
- Optional live checks: `mix droid.install && mix droid.compat`
