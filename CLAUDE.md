# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JourDash is a Phoenix 1.8 LiveView demo of a food delivery service, built to showcase the Journey durable-workflow library. Each delivery trip is a Journey execution; the UI is a reactive view over Journey state. A live instance runs at https://jourdash.gojourney.dev.

Toolchain: Elixir 1.19.3 / OTP 28.2 (see `.tool-versions`). Postgres 16 is required.

## Common Commands

```bash
# One-time setup (deps, both databases, assets)
docker run --rm --name jourdash-postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d postgres:16
mix setup

# Development server (http://localhost:4000; LiveDashboard at /dev/dashboard)
mix phx.server
iex -S mix                             # drive trips by hand: JourDash.Trip.start(2, 5), Journey.set(trip, :picked_up?, true)

# Tests (the alias creates/migrates both test DBs first)
mix test
mix test test/jour_dash/delivery_test.exs   # end-to-end delivery; ~80s wall clock, tick-driven
mix test --failed

# Lint / format
mix format
mix credo

# Pre-commit: compile --warnings-as-errors, deps.unlock --unused, format --check-formatted, credo, test
# Runs in MIX_ENV=test (preferred_envs in mix.exs). CI runs the same checks on every PR.
mix precommit

# Database
mix ecto.reset                         # drop + recreate + migrate both repos
```

## Architecture

### The trip is a Journey graph

Everything about a delivery lives in one Journey execution of the graph defined in `lib/jour_dash/trip/graph.ex` (`JourDash.Trip.Graph`, name `"Food Delivery Trip"`, version `"v1.0"`). The graph is registered in `config/config.exs` under `config :journey, :graphs`, and the Journey background sweeper period is lowered to 5s there so simulated GPS ticks feel interactive.

`JourDash.Trip` (`lib/jour_dash/trip.ex`) is the thin entry point: `start/2` creates an execution and sets the initial inputs.

Node flow, in dependency order:

- **Inputs**: `location_driver`, `location_pickup`, `location_dropoff`, `item_to_deliver`, `delivery_price_cents` (set at start), then `picked_up?`, `handed_off?`, `dropped_off?`, `rating` (set later by the UI).
- **GPS simulation**: `time_simulation` is a `tick_recurring` (every 5s) that stays active until `payment_collection` exists. It unblocks the `mutate` node `driver_location_current_update`, which advances `location_driver` by one step (`mutates: :location_driver`).
- **`current_activity`** (compute): recomputed whenever the driver location or any flag changes. Produces labels like `driving_to_pickup`, `waiting_for_item`, `driving_to_dropoff`, `waiting_for_customer`, `handed_off`, `dropped_off`, `payment_collected`. The UI buttons key off these strings.
- **`payment_collection`** → **`trip_completed_at`**: fire once `handed_off?` or `dropped_off?` is true. `trip_completed_at != nil` is the UI's "done" signal.
- **`rating_reminder_timer`** (`tick_once`, +10s after payment) → **`rating_reminder`** (compute, only if `rating` is still unset).
- **`trip_history`** (historian): append-only audit log of the key nodes; what the expandable history panel renders.

Three modules split the responsibilities:

- `JourDash.Trip.Graph` declares nodes and dependencies only.
- `JourDash.Trip.Computations` holds the pure functions attached to compute/mutate nodes. They receive the execution's values map and return `{:ok, value}`.
- `JourDash.Trip.PubSubNotifications` holds the `f_on_save` callbacks. Side effects that must reach the UI go here, not in Computations.

Several nodes set `keep_latest_completed_computations: 10` so the frequently-recomputing GPS nodes do not accumulate unbounded history.

### PubSub topics (the contract between Journey and LiveView)

| Topic | Message | Published by | Consumed by |
|---|---|---|---|
| `new_trips` | `{:trip_created, id}` | `Home.Index` on button click | `Home.Index` |
| `trip_completed` | `{:trip_completed, id}` | `trip_completed_at` f_on_save | `Home.Index` (refresh counts) |
| `current_activity_update_#{id}` | `{:activity_changed, id, activity}` | `current_activity` f_on_save | `Trip.Index` |
| `history_update_#{id}` | `{:history_changed, id, history}` | `trip_history` f_on_save | `Trip.Index` |
| `driver_location_update_#{id}` | `{:driver_location_changed, id, location}` | `driver_location_current_update` f_on_save | `Trip.Index` |

Journey fires a node-scoped `f_on_save` only when the node's own value was actually written. A compute node that recomputes to the same value (for example `current_activity` staying `driving_to_pickup` while the car moves) does not fire it. That is why the GPS mutate node has its own `f_on_save`: its own value is written on every tick, so it is the reliable per-tick signal to the UI.

### LiveView layering

- **`JourDashWeb.Live.Home.Index`** (`/`) is the only route. It loads trip ids, quick counts via `Journey.count_executions`, and full analytics via `Journey.Insights.FlowAnalytics`. It caps concurrent trips with `drivers_available/0` (5). For each trip it renders a nested LiveView with `live_render`, passing the trip id in the session.
- **`JourDashWeb.Live.Trip.Index`** is one nested LiveView per trip. It subscribes to that trip's three topics, and on any message reloads the whole values map with `Journey.values(trip, include_unset_as_nil: true)`. Button handlers do an optimistic assign and call `Journey.set` inside `Task.start` so the UI never blocks on Journey. Expanding a card calls `Journey.Tools.introspect/1` for the execution introspection panel.
- **`JourDashWeb.Live.Components.TC`** and its `TC.*` submodules are plain function components that render from `@trip_values`; they hold no state and emit events handled by `Trip.Index`.

Both LiveViews do real work only when `connected?/1` is true; the dead render shows nothing.

### Data stores

Two Ecto repos, two databases: `JourDash.Repo` (app, currently unused by any schema) and `Journey.Repo` (all workflow state). Dev DBs are `jour_dash_dev` and `journey_jourdash_dev`; prod reads `DATABASE_URL` and `DATABASE_JOURNEY_URL` in `config/runtime.exs`.

### Testing notes

- Tests hit a real Postgres. Only `JourDash.Repo` is in the SQL sandbox; `Journey.Repo` is not, so Journey executions created by tests persist in the test DB.
- `test/jour_dash/delivery_test.exs` drives a trip with `Journey.get(..., wait: ...)` and real ticks, so it runs for over a minute. The LiveView equivalent in `test/jour_dash_web/live/trip_completion_test.exs` is currently `@tag :skip`.
- `test/support/liveview_test_helpers.ex` provides `poll_for_element/4` for waiting on tick-driven DOM changes.

### Deployment

`.github/workflows/validate.yml` lints and tests every PR. Pushes to `main` additionally build the Docker image and deploy it to Google Cloud Run (`main-validate-deploy.yml`).

## Project Guidelines

- Run `mix precommit` before committing.
- Business logic for new graph nodes goes in `Computations`; UI-facing side effects go in `PubSubNotifications` as `f_on_save` callbacks.
- Use `:req` (Req) for HTTP requests.
- See `AGENTS.md` for Phoenix 1.8, LiveView, Ecto, and Elixir-specific guidelines (streams, forms, HEEx syntax, JS hooks).
