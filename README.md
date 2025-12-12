# JourDash: Delivering snacks with Journey

This application shows a basic food delivery service.

The application uses Journey (a durable workflow engine) to define and execute its workflows.

At the time of this writing, this application is hosted on [jourdash.gojourney.dev](https://jourdash.gojourney.dev/). You are welcome to head there, run a few deliveries, and check out the application's analytics.

## Setup

Run `mix setup` to install and set up dependencies.

Note that Journey uses Postgres for persistence. You can spin up an ephemeral (due to `--rm`) PostgreSQL service in Docker with the following command:

```bash
$ docker run --rm --name jourdash-postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d postgres:16
```

## "Deliver" "Food", via LiveView UI

To run the application, start your Phoenix application as you would normally:

```
💙💛 ~/src/jour_dash $ mix phx.server
[info] Migrations already up
[info] Running JourDashWeb.Endpoint with Bandit 1.8.0 at 127.0.0.1:4000 (http)
[info] Access JourDashWeb.Endpoint at http://localhost:4000
...
```

Then navigate to http://localhost:4000 to run a few "deliveries."

Remember to "Pick Up" and "Hand Off" or "Drop Off" when appropriate.

To play with the "durable" part of "durable workflow", try reloading the page, opening multiple browsers, and restarting the service. Watch deliveries proceed as if nothing happened.

## Observe a "Delivery", via a Test

You can watch a delivery by running a test, which spins up and directs an execution of the delivery workflow.

Once the delivery is completed, the test dumps its recorded history.

Below is an example of a test run, from driving to the pickup location, to sending a scheduled reminder to the customer. The "delivery" is observed in real time (~80 seconds), and also detailed in the recorded history of the trip.

```
💙💛 ~/src/jour_dash $ mix test test/jour_dash/delivery_test.exs
Running ExUnit with seed: 918636, max_cases: 20

[1765222328] started trip EXECATY4B4Z9367EBYJRVT7X: picking up 🍊 at 2, and delivering it to 5
[1765222328] driving_to_pickup
[1765222355] waiting_for_item
[1765222355] 🍊 picked up
[1765222356] driving_to_dropoff
[1765222396] waiting_for_customer
[1765222396] 🍊 dropped off
[1765222396] payment collected: 550 cents
[1765222411] rating reminder set: reminder sent
--------------------------------
trip history:
[1765222328] current_activity: 'driving_to_pickup' (rev. 7)
[1765222353] current_activity: 'waiting_for_item' (rev. 21)
[1765222355] picked_up?: 'true' (rev. 24)
[1765222356] current_activity: 'driving_to_dropoff' (rev. 27)
[1765222393] current_activity: 'waiting_for_customer' (rev. 46)
[1765222396] dropped_off?: 'true' (rev. 49)
[1765222396] current_activity: 'dropped_off' (rev. 56)
[1765222396] payment_collection: 'payment collected: 550 cents' (rev. 55)
[1765222396] current_activity: 'payment_collected' (rev. 64)
[1765222409] rating_reminder: 'reminder sent' (rev. 73)
--------------------------------
.
Finished in 83.1 seconds (0.00s async, 83.1s sync)
1 test, 0 failures
```

## "Deliver" "Food", in IEx

If you want to "run" your own delivery or two, you can do this in IEx, using the test ([./test/jour_dash/delivery_test.exs](./test/jour_dash/delivery_test.exs)) as an example.

Here is an example of delivering 🍇, via IEx, and examining the trip's history after completion:

```elixir
💙💛 ~/src/jour_dash $ iex -S mix
Erlang/OTP 27 [erts-15.1.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

[info] Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> trip = JourDash.Trip.start(2, 5); :ok
:ok
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "driving_to_pickup"
iex(2)> {:ok, activity, last_revision} = Journey.get(trip, :current_activity, wait: :any)
{:ok, "driving_to_pickup", 7}
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "waiting_for_item"
iex(3)> {:ok, activity, last_revision} = Journey.get(trip, :current_activity, wait: :any)
{:ok, "waiting_for_item", 19}
iex(4)> Journey.values(trip)
%{
  created_at: 1765225267,
  location_driver: 2,
  location_pickup: 2,
  location_dropoff: 5,
  item_to_deliver: "🍇",
  delivery_price_cents: 550,
  current_activity: "waiting_for_item",
  trip_history: [
    %{
      "metadata" => nil,
      "node" => "current_activity",
      "revision" => 19,
      "timestamp" => 1765225284,
      "value" => "waiting_for_item"
    },
    %{
      "metadata" => nil,
      "node" => "current_activity",
      "revision" => 7,
      "timestamp" => 1765225267,
      "value" => "driving_to_pickup"
    }
  ],
  time_simulation: 1765225316,
  driver_location_current_update: "updated :location_driver",
  execution_id: "EXECXX6A6DT0A22ZVGVL96GX",
  last_updated_at: 1765225310
}
iex(5)> Journey.set(trip, :picked_up?, true); :ok
:ok
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: picked_up?: true
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "driving_to_dropoff"
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "waiting_for_customer"
iex(6)> Journey.set(trip, :handed_off?, true); :ok
:ok
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: handed_off?: true
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "handed_off"
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: payment_collection: "payment collected: 550 cents"
[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: current_activity: "payment_collected"
[info] Subject: 🍇
Dear Customer,
Rate this delivery ('EXECXX6A6DT0A22ZVGVL96GX').
Thank you,
JourDash.

[info] [EXECXX6A6DT0A22ZVGVL96GX]: trip_history updated: rating_reminder: "reminder sent"
iex(7)> Journey.get(trip, :trip_history)
{:ok,
 [
   %{
     "metadata" => nil,
     "node" => "rating_reminder",
     "revision" => 107,
     "timestamp" => 1765225417,
     "value" => "reminder sent"
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 99,
     "timestamp" => 1765225406,
     "value" => "payment_collected"
   },
   %{
     "metadata" => nil,
     "node" => "payment_collection",
     "revision" => 91,
     "timestamp" => 1765225406,
     "value" => "payment collected: 550 cents"
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 88,
     "timestamp" => 1765225406,
     "value" => "handed_off"
   },
   %{
     "metadata" => nil,
     "node" => "handed_off?",
     "revision" => 83,
     "timestamp" => 1765225406,
     "value" => true
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 76,
     "timestamp" => 1765225391,
     "value" => "waiting_for_customer"
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 53,
     "timestamp" => 1765225355,
     "value" => "driving_to_dropoff"
   },
   %{
     "metadata" => nil,
     "node" => "picked_up?",
     "revision" => 48,
     "timestamp" => 1765225355,
     "value" => true
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 19,
     "timestamp" => 1765225284,
     "value" => "waiting_for_item"
   },
   %{
     "metadata" => nil,
     "node" => "current_activity",
     "revision" => 7,
     "timestamp" => 1765225267,
     "value" => "driving_to_pickup"
   }
 ], 109}
iex(8)>
```

## References

* The Journey durable workflow at the core of this application: [./lib/jour_dash/trip/graph.ex](./lib/jour_dash/trip/graph.ex).
* Journey docs: https://hexdocs.pm/journey/readme.html
* Journey codebase: https://github.com/shipworthy/journey
