defmodule JourDash.Trip.Graph do
  @moduledoc """
  The module defines the workflow for Food Delivery trips.

  Note that `compute()` nodes have functions attached to them
  (e.g. `:remind_customer_to_leave_rating/1` in `:rating_reminder`).

  These functions are called when required upstream dependencies
  are met ("reactivity").

  If a computation function fails, Journey will retry the function,
  with "at-least-once" guarantee, subject to the function's retry
  policy  ("reliability").

  Journey will execute computation functions on any of the replicas
  of the application ("horizontal scalability").

  Values returned by computation functions are immediately persisted
  ("durability").

  Journey workflows are reactive, reliable, horizontally scalable, and
  durable.

  Journey Documentation: https://hexdocs.pm/journey
  """

  import Journey.Node
  import Journey.Node.Conditions
  import Journey.Node.UpstreamDependencies
  require Logger

  alias JourDash.Trip.Computations

  def name(), do: "Food Delivery Trip"
  def version(), do: "v1.0"

  def new() do
    Journey.new_graph(
      name(),
      version(),
      [
        compute(:created_at, [], fn _ -> {:ok, System.system_time(:second)} end),

        # Initial data elements of the delivery trip.
        input(:location_driver),
        input(:location_pickup),
        input(:location_dropoff),
        input(:item_to_deliver),
        input(:delivery_price_cents),

        # Externally supplied inputs.
        #
        # This value is set to `true` when the item was picked up by the driver.
        input(:picked_up?),
        # This value is set to `true` when the item was handed off to the customer.
        input(:handed_off?),
        # This value is set to `true` when the item was dropped off at the customer's location.
        input(:dropped_off?),
        # This holds the customer-supplied rating of the delivery.
        input(:rating),

        # Various computed properties and side effects.
        #
        # Computes the current status label (e.g.,  "driving_to_pickup",
        # "waiting_for_item").
        compute(
          :current_activity,
          unblocked_when(
            :or,
            [
              {:location_driver, &provided?/1},
              {:picked_up?, &provided?/1},
              {:dropped_off?, &provided?/1},
              {:handed_off?, &provided?/1},
              {:payment_collection, &provided?/1}
            ]
          ),
          &Computations.current_activity_name/1,
          f_on_save: fn trip_id, {:ok, new_activity} ->
            Logger.debug("#{trip_id}: current_activity updated, new activity: #{new_activity}")

            Phoenix.PubSub.broadcast(
              JourDash.PubSub,
              "current_activity_update_#{trip_id}",
              {:activity_changed, trip_id, new_activity}
            )

            {:ok, "new activity notified"}
          end
        ),

        # Collects payment upon delivery completion.
        compute(
          :payment_collection,
          unblocked_when(
            :or,
            [
              {:handed_off?, &true?/1},
              {:dropped_off?, &true?/1}
            ]
          ),
          &Computations.collect_payment/1
        ),

        # Record payment collection time.
        compute(
          :trip_completed_at,
          [:payment_collection],
          fn _ -> {:ok, System.system_time(:second)} end,
          f_on_save: fn trip_id, {:ok, trip_completed_at} ->
            Logger.debug("[#{trip_id}] trip_completed_at: #{trip_completed_at}")

            Phoenix.PubSub.broadcast(
              JourDash.PubSub,
              "trip_completed",
              {:trip_completed, trip_id}
            )

            {:ok, "trip_completed_at notification sent"}
          end
        ),

        # Schedules a reminder for the customer to rate the trip if
        # not yet rated.
        #
        # Schedules a tick for the reminder.
        tick_once(
          :rating_reminder_timer,
          [:payment_collection],
          fn _ -> {:ok, System.system_time(:second) + 10} end
        ),
        # Issues the reminder once the tick fires.
        compute(
          :rating_reminder,
          unblocked_when(:and, [
            {:rating_reminder_timer, &provided?/1},
            {:rating, fn x -> not provided?(x) end}
          ]),
          &Computations.remind_customer_to_leave_rating/1
        ),

        # Audit log recording key lifecycle events.
        historian(
          :trip_history,
          unblocked_when(
            :or,
            [
              {:current_activity, &provided?/1},
              {:picked_up?, &provided?/1},
              {:dropped_off?, &provided?/1},
              {:handed_off?, &provided?/1},
              {:payment_collection, &provided?/1},
              {:rating_reminder, &provided?/1}
            ]
          ),
          f_on_save: fn trip_id,
                        {:ok, [%{"node" => node, "value" => value} | _older_history]} =
                          updated_history ->
            Logger.info("[#{trip_id}]: trip_history updated: #{node}: #{inspect(value)}")

            Phoenix.PubSub.broadcast(
              JourDash.PubSub,
              "history_update_#{trip_id}",
              {:history_changed, trip_id, updated_history}
            )

            {:ok, "trip_history_updated"}
          end
        ),

        # GPS simulation: providing `:location_driver` updates.
        #
        # Schedules a recurring tick to drive the GPS simulation.
        tick_recurring(
          :time_simulation,
          unblocked_when(:payment_collection, fn x -> not provided?(x) end),
          fn _ -> {:ok, System.system_time(:second) + 6} end
        ),
        # Generates a simulated GPS reading on every tick and stores it
        # in :location_driver.
        mutate(
          :driver_location_current_update,
          [:time_simulation],
          &Computations.new_driver_simulated_gps_location/1,
          mutates: :location_driver,
          update_revision_on_change: true
        )
      ]
    )
  end
end
