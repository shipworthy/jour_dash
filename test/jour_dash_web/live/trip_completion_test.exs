defmodule JourDashWeb.Live.TripCompletionTest do
  @moduledoc """
  End-to-end LiveView integration test for the happy path trip completion flow.

  This test covers the same sequence as JourDash.DeliveryTest but through the
  LiveView UI, verifying that the full reactive pipeline works:
  User action -> Journey state change -> PubSub broadcast -> LiveView update -> DOM change
  """

  # Run as async: false to avoid PubSub race conditions between test processes
  use JourDashWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import JourDashWeb.LiveViewTestHelpers
  require Logger

  @moduletag :integration

  describe "successful trip completion flow" do
    @tag :skip
    @tag timeout: 180_000
    test "driver completes trip with pickup and drop off, receives rating reminder", %{conn: conn} do
      # Step 1: Navigate to homepage and mount LiveView
      {:ok, view, html} = live(conn, "/")

      # Step 2: Verify the page loaded correctly
      assert html =~ "JourDash"
      assert has_element?(view, "#start-a-new-trip-button-id")
      Logger.info("Homepage loaded successfully")

      # Step 3: Click the start trip button to create a new trip
      print("Clicking start trip button")
      render_click(view, "on_start_trip_button_click", %{})

      # Step 4: Extract the trip ID from the notification element
      assert has_element?(view, "#new-trip-created-id")

      trip_id =
        view
        |> render()
        |> Floki.parse_document!()
        |> Floki.find("#new-trip-created-id")
        |> Floki.text()
        |> String.trim()

      print("Trip created: #{trip_id}")

      # Step 5: Verify initial state - trip card is visible
      assert has_element?(view, "#tc-#{trip_id}-id")

      # Step 6: Wait for driver to reach pickup location (waiting_for_item state)
      # The pickup button only appears when current_activity == "waiting_for_item"
      print("Waiting for driver to reach pickup location...")

      pickup_ready =
        poll_for_element(
          view,
          "#pickup-item-#{trip_id}-button-id",
          90_000,
          "waiting for pickup button to appear"
        )

      assert pickup_ready, "Driver should reach pickup location within allotted time"
      print("Driver reached pickup location - pickup button is visible")

      # Step 7: Verify the activity shows "waiting_for_item"
      activity_html =
        view
        |> element("#activity-#{trip_id}-id")
        |> render()

      assert activity_html =~ "waiting_for_item"

      # Step 8: Click the pickup button
      # Find the child LiveView for this specific trip
      trip_view = find_live_child(view, "trip-lv-#{trip_id}")
      print("Clicking pickup button")
      render_click(trip_view, "on_pickup_item_button_click", %{})

      # Step 9: Wait for driver to reach dropoff location (waiting_for_customer state)
      print("Waiting for driver to reach dropoff location...")

      dropoff_ready =
        poll_for_element(
          view,
          "#drop-off-item-#{trip_id}-button-id",
          90_000,
          "waiting for drop off button to appear"
        )

      assert dropoff_ready, "Driver should reach dropoff location within allotted time"
      print("Driver reached dropoff location - drop off button is visible")

      # Step 10: Verify the activity shows "waiting_for_customer"
      activity_html =
        view
        |> element("#activity-#{trip_id}-id")
        |> render()

      assert activity_html =~ "waiting_for_customer"

      # Step 11: Click the drop off button to complete delivery
      print("Clicking drop off button")
      render_click(trip_view, "on_drop_off_item_button_click", %{})

      # Step 12: Wait for completion status to appear
      print("Waiting for trip completion...")

      completed =
        poll_for_element(
          view,
          "#completed-#{trip_id}-id",
          5_000,
          "waiting for completion checkmark"
        )

      assert completed, "Trip should show completion status"
      print("Trip completed successfully")

      # Step 13: Verify the dropped off badge appears
      assert has_element?(view, "#dropped-off-#{trip_id}-id")

      dropped_off_html =
        view
        |> element("#dropped-off-#{trip_id}-id")
        |> render()

      assert dropped_off_html =~ "📦"

      # Step 14: Wait for rating reminder to be sent (10 seconds after payment)
      print("Waiting for rating reminder...")

      rating_reminder_sent =
        poll_for_element(
          view,
          "#rating-reminder-#{trip_id}-id",
          25_000,
          "waiting for rating reminder"
        )

      assert rating_reminder_sent, "Rating reminder should be sent within allotted time"
      print("Rating reminder sent")

      # Step 15: Verify the rating reminder badge appears
      rating_reminder_html =
        view
        |> element("#rating-reminder-#{trip_id}-id")
        |> render()

      assert rating_reminder_html =~ "rate this"

      # Step 16: Verify final state via Journey API
      values = Journey.values(trip_id)
      assert values.dropped_off? == true
      assert values.payment_collection != nil
      assert values.rating_reminder != nil
      assert values.trip_completed_at != nil

      print("Test completed successfully - trip #{trip_id} completed with rating reminder")
    end

    defp print(message) do
      IO.puts("[#{System.system_time(:second)}] #{message}")
    end
  end
end
