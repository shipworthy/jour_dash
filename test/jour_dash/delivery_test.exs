defmodule JourDash.DeliveryTest do
  use JourDash.DataCase

  @tag timeout: 300_000
  test "running a delivery from start to finish" do
    trip = JourDash.Trip.start(2, 5)
    values = Journey.values(trip)

    print(
      "started trip #{values.execution_id}: picking up #{values.item_to_deliver} at #{values.location_pickup}, and delivering it to #{values.location_dropoff}"
    )

    try do
      {:ok, activity, last_revision} = Journey.get(trip, :current_activity, wait: :any)
      print(activity)
      assert activity == "driving_to_pickup"

      {:ok, activity, last_revision} =
        Journey.get(trip, :current_activity, wait: {:newer_than, last_revision}, timeout: 150_000)

      print(activity)
      assert activity == "waiting_for_item"

      Journey.set(trip, :picked_up?, true)
      print("#{values.item_to_deliver} picked up")

      {:ok, activity, last_revision} =
        Journey.get(trip, :current_activity, wait: {:newer_than, last_revision}, timeout: 150_000)

      print(activity)
      assert activity == "driving_to_dropoff"

      {:ok, activity, _} =
        Journey.get(trip, :current_activity, wait: {:newer_than, last_revision}, timeout: 150_000)

      print(activity)
      assert activity == "waiting_for_customer"

      Journey.set(trip, :dropped_off?, true)
      print("#{values.item_to_deliver} dropped off")
      {:ok, payment_collection, _} = Journey.get(trip, :payment_collection, wait: :any)
      print(payment_collection)
      {:ok, rating_reminder_set, _} = Journey.get(trip, :rating_reminder, wait: :any)
      print("rating reminder set: #{rating_reminder_set}")

      IO.puts("--------------------------------")
      IO.puts("trip history:")

      trip
      |> Journey.values()
      |> Map.get(:trip_history)
      |> Enum.reverse()
      |> Enum.each(fn trip_history_item ->
        node = trip_history_item["node"]
        value = trip_history_item["value"]
        revision = trip_history_item["revision"]
        timestamp = trip_history_item["timestamp"]
        IO.puts("[#{timestamp}] #{node}: '#{value}' (rev. #{revision})")
      end)

      IO.puts("--------------------------------")
    rescue
      error ->
        IO.puts("Error: #{inspect(error)}")
        values = Journey.values(trip)
        IO.puts("values: #{inspect(values, pretty: true)}")
        reraise error, __STACKTRACE__
    end
  end

  defp print(message) do
    IO.puts("[#{System.system_time(:second)}] #{message}")
  end
end
