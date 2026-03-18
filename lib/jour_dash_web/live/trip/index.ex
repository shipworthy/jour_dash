defmodule JourDashWeb.Live.Trip.Index do
  @moduledoc false
  use JourDashWeb, :live_view

  require Logger

  def mount(params, session, socket) do
    Logger.debug("Mounting JourDashWeb.Live.Trip.Index LiveView #{inspect(params)}")

    connected? = connected?(socket)

    time_zone =
      socket
      |> get_connect_params()
      |> case do
        nil -> nil
        params -> Map.get(params, "time_zone")
      end

    socket =
      assign(socket, connected?: connected?)
      |> assign(:expanded?, false)
      |> assign(:introspection, nil)
      |> assign(:introspection_expanded?, false)
      |> assign(time_zone: time_zone)
      |> mount_with_connected(params, session, connected?)

    {:ok, socket}
  end

  def mount_with_connected(socket, params, session, connected?) when connected? == true do
    trip =
      if session["trip"] != nil do
        session["trip"]
      else
        if is_map(params) do
          Map.get(params, "trip")
        else
          nil
        end
      end

    if trip != nil do
      :ok = Phoenix.PubSub.subscribe(JourDash.PubSub, "current_activity_update_#{trip}")
      :ok = Phoenix.PubSub.subscribe(JourDash.PubSub, "history_update_#{trip}")
    end

    socket
    |> load_trip_to_socket_assigns(trip)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.debug("Not connected to LiveView")
    socket
  end

  def handle_info({:activity_changed, trip_id, new_activity}, socket) do
    Logger.debug("[#{trip_id}]: :activity_changed new activity: #{new_activity}")

    socket =
      socket
      |> load_trip_to_socket_assigns(trip_id)

    {:noreply, socket}
  end

  def handle_info({:history_changed, trip_id, _updated_history}, socket) do
    Logger.debug("[#{trip_id}]: :history_changed")

    socket =
      socket
      |> load_trip_to_socket_assigns(trip_id)

    {:noreply, socket}
  end

  def handle_event("on_trip_card_chevron_down_click", _params, socket) do
    expanding? = not socket.assigns.expanded?
    Logger.info("on_trip_card_chevron_down_click: #{if expanding?, do: "expanding", else: "collapsing"}")

    introspection =
      if expanding?,
        do: Journey.Tools.introspect(socket.assigns.trip),
        else: nil

    socket =
      socket
      |> assign(:expanded?, expanding?)
      |> assign(:introspection, introspection)
      |> assign(:introspection_expanded?, if(expanding?, do: socket.assigns.introspection_expanded?, else: false))

    {:noreply, socket}
  end

  def handle_event("on_introspection_toggle_click", _params, socket) do
    expanding? = not socket.assigns.introspection_expanded?
    Logger.info("on_introspection_toggle_click: #{if expanding?, do: "expanding", else: "collapsing"}")

    {:noreply, assign(socket, :introspection_expanded?, expanding?)}
  end

  def handle_event("on_pickup_item_button_click", _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: on_pickup_item_button_click")

    Task.start(fn ->
      Journey.set(trip, :picked_up?, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :picked_up?, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("on_hand_off_item_button_click" = event, _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: #{event}")

    Task.start(fn ->
      Journey.set(trip, :handed_off?, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :handed_off?, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("on_drop_off_item_button_click" = event, _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: #{event}")

    Task.start(fn ->
      Journey.set(trip, :dropped_off?, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :dropped_off?, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    trip = socket.assigns[:trip]
    Logger.debug("#{trip}: Terminating LiveView (reason: #{inspect(reason)})")
    :ok
  end

  def load_trip_to_socket_assigns(socket, trip) when trip == nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")

    socket
    |> assign(:trip, nil)
    |> assign(:trip_values, nil)
  end

  def load_trip_to_socket_assigns(socket, trip) when trip != nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")
    trip_values = Journey.values(trip, include_unset_as_nil: true)

    introspection =
      if socket.assigns.expanded?,
        do: Journey.Tools.introspect(trip),
        else: socket.assigns[:introspection]

    socket
    |> assign(:trip, trip)
    |> assign(:trip_values, trip_values)
    |> assign(:introspection, introspection)
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div :if={@connected?} class="space-y-4">
        <JourDashWeb.Live.Components.TC.render
          time_zone={@time_zone}
          trip_values={@trip_values}
          trip={@trip}
          expanded?={@expanded?}
          introspection={@introspection}
          introspection_expanded?={@introspection_expanded?}
        />
      </div>
    </div>
    """
  end
end
