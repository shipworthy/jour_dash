# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JourDash is a Phoenix 1.8 LiveView application that simulates a food delivery service. It uses the Journey library (workflow orchestration) to manage delivery trip lifecycles with reactive, durable workflows.

## Common Commands

```bash
# Development server
mix phx.server

# Run tests
mix test
mix test test/path/to/test.exs        # Single file
mix test --failed                      # Retry failed tests

# Pre-commit (run before committing)
mix precommit                          # Compiles with warnings-as-errors, unlocks unused deps, formats, runs tests

# Database
mix ecto.setup                         # Create, migrate, seed
mix ecto.reset                         # Drop and re-setup
mix ecto.gen.migration migration_name  # Generate migration

# Assets
mix assets.setup                       # Install tailwind/esbuild
mix assets.build                       # Build CSS/JS
```

## Architecture

### Core Domain: Trip Workflow

The application models food delivery trips using Journey workflows:

- **`JourDash.Trip`** (`lib/jour_dash/trip.ex`) - Entry point for creating and listing trips
- **`JourDash.Trip.Graph`** (`lib/jour_dash/trip/graph.ex`) - Defines the workflow graph with:
  - Input nodes: `location_driver`, `location_pickup`, `location_dropoff`, `picked_up?`, `handed_off?`, `dropped_off?`, `rating`
  - Computed nodes: `current_activity`, `payment_collection`, `rating_reminder`
  - GPS simulation via `tick_recurring` and `mutate` nodes
  - PubSub broadcasts on state changes for LiveView updates
- **`JourDash.Trip.Computations`** (`lib/jour_dash/trip/computations.ex`) - Business logic functions called by workflow nodes

### Web Layer

- **`JourDashWeb.Live.Home.Index`** - Main LiveView displaying all trips, subscribes to PubSub for real-time updates
- **`JourDashWeb.Live.Components.TC`** - Trip card component with subcomponents:
  - `TC.Header`, `TC.TripMap`, `TC.Buttons`, `TC.StatusLine`, `TC.ExpandableHistory`
- **`JourDashWeb.Live.Components.Analytics`** - Analytics dashboard component

### Key Libraries

- **Journey** (`~> 0.10.40`) - Workflow orchestration with reactive computations, ticks, and durability
- **Req** - HTTP client (prefer over HTTPoison/Tesla)
- Uses two Ecto repos: `JourDash.Repo` and `Journey.Repo`

## Project Guidelines

- Run `mix precommit` before committing changes
- Use `:req` (Req) for HTTP requests
- See `AGENTS.md` for Phoenix 1.8, LiveView, Ecto, and Elixir-specific guidelines
