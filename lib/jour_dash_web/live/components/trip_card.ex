defmodule JourDashWeb.Live.Components.TC do
  @moduledoc false

  use JourDashWeb, :html
  require Logger

  attr :time_zone, :string, required: true
  attr :trip_values, :map, required: true
  attr :trip, :string, required: true
  attr :expanded?, :boolean, required: true
  attr :introspection, :string, default: nil
  attr :introspection_expanded?, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div id={"tc-#{@trip}-id"} class="m-3">
      <div
        id={"trip-card-inner-container-#{@trip}-id"}
        class={
          ["text-sm font-mono border-1 rounded-md p-4 bg-base-100", "relative"] ++
            if @trip_values.trip_completed_at != nil and @expanded? == false,
              do: ["opacity-50"],
              else: []
        }
      >
        <JourDashWeb.Live.Components.TC.Header.render trip={@trip} trip_values={@trip_values} />
        <JourDashWeb.Live.Components.TC.TripMap.render trip={@trip} trip_values={@trip_values} />
        <JourDashWeb.Live.Components.TC.Buttons.render trip={@trip} trip_values={@trip_values} />
        <JourDashWeb.Live.Components.TC.StatusLine.render trip={@trip} trip_values={@trip_values} />
        <!-- Expand/collapse chevron -->
        <JourDashWeb.Live.Components.TC.ExpandableHistory.render
          trip={@trip}
          trip_values={@trip_values}
          expanded?={@expanded?}
          time_zone={@time_zone}
          introspection={@introspection}
          introspection_expanded?={@introspection_expanded?}
        />
      </div>
    </div>
    """
  end
end
