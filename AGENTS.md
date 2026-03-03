# AGENTS.md - Jido.Droid

## Overview

Jido.Droid is the Factory Droid CLI adapter for Jido.Harness. It normalizes Droid's JSONL event stream into the Harness protocol.

## Key Modules

- `Jido.Droid` — Public facade (`run/2`, `run_request/2`)
- `Jido.Droid.Adapter` — `Jido.Harness.Adapter` implementation
- `Jido.Droid.CLI` — Droid CLI discovery
- `Jido.Droid.Compatibility` — Runtime compatibility checks
- `Jido.Droid.Mapper` — Event normalization
- `Jido.Droid.Stream` — Port-based streaming
- `Jido.Droid.Error` — Splode error types

## Conventions

- Structs use the Zoi schema pattern where applicable
- Errors use Splode (`Jido.Droid.Error`)
- Elixir `~> 1.18`
- Run `mix quality` before committing
- Use conventional commit format

## Commands

- `mix test` — Run tests
- `mix quality` — Full quality check (compile, format, credo, dialyzer, doctor)
- `mix droid.install` — Check/install Droid CLI
- `mix droid.compat` — Validate compatibility
- `mix droid.smoke "prompt"` — Run smoke test
