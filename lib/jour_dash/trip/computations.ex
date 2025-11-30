defmodule JourDash.Trip.Computations do
  @moduledoc """
  This module defines computations invoked during executions of the Trip graph.

  These functions are invoked by Journey, which handles their execution
  guarantees (reactivity, retries, horizontal scalability, persistence).
  """
  require Logger

  @doc """
  Computes a concise label for the current state of the delivery (e.g.
  "driving_to_pickup", "dropped_off") based on its various attributes.
  """
  def current_activity_name(trip_values) do
    location_driver = Map.get(trip_values, :location_driver, 0)
    location_pickup = Map.get(trip_values, :location_pickup, 0)
    location_dropoff = Map.get(trip_values, :location_dropoff, 0)
    picked_up? = Map.get(trip_values, :picked_up?, false)
    dropped_off? = Map.get(trip_values, :dropped_off?, false)
    handed_off? = Map.get(trip_values, :handed_off?, false)
    payment_collection = Map.get(trip_values, :payment_collection, nil)

    cond do
      payment_collection != nil ->
        {:ok, "payment_collected"}

      dropped_off? ->
        {:ok, "dropped_off"}

      handed_off? ->
        {:ok, "handed_off"}

      picked_up? ->
        if location_driver < location_dropoff do
          {:ok, "driving_to_dropoff"}
        else
          {:ok, "waiting_for_customer"}
        end

      location_driver < location_pickup ->
        {:ok, "driving_to_pickup"}

      location_driver >= location_pickup and !picked_up? ->
        {:ok, "waiting_for_item"}
    end
  end

  @doc """
  Computes the next simulated GPS location for the driver, depending on
  where the driver currently is, and what they are doing (e.g. driving
  to destination or waiting to pick up the item).
  """
  def new_driver_simulated_gps_location(
        %{
          location_driver: location_driver,
          location_pickup: location_pickup,
          location_dropoff: location_dropoff
        } = trip_values
      ) do
    picked_up? = Map.get(trip_values, :picked_up?, false)

    cond do
      location_driver >= location_dropoff ->
        {:ok, location_driver}

      location_driver == location_pickup and not picked_up? ->
        {:ok, location_driver}

      true ->
        {:ok, location_driver + 1}
    end
  end

  @doc """
  "Collects" "payment" for the delivery.
  """
  def collect_payment(trip_values) do
    {:ok, "payment collected: #{trip_values.delivery_price_cents} cents"}
  end

  @doc """
  "Sends" a reminder to the customer to rate their experience.
  """
  def remind_customer_to_leave_rating(trip_values) do
    Logger.info("""
    Subject: #{trip_values.item_to_deliver}
    Dear Customer,
    Let us know how we did!
    https://jourdash.example.com/rate/#{trip_values.execution_id}.
    Thank you,
    JourDash.
    """)

    {:ok, "reminder sent"}
  end
end
