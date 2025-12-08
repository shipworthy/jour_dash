defmodule JourDashWeb.Live.Components.TC.StatusLine do
  @moduledoc false

  use JourDashWeb, :html

  attr :trip, :string, required: true
  attr :trip_values, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="font-mono my-1 py-1">
      <p class="my-2">
        <span
          id={"location-#{@trip}-id"}
          class={[
            "font-mono",
            if(@trip_values.trip_completed_at == nil,
              do: "badge badge-info",
              else: "badge badge-neutral"
            )
          ]}
        >
          <.icon name="hero-map" class="w-4 h-4" /> {@trip_values.location_driver + 1}
        </span>
        <span
          :if={@trip_values.trip_completed_at == nil}
          id={"activity-#{@trip}-id"}
          class={[
            "font-mono",
            if(@trip_values.trip_completed_at == nil,
              do: "badge badge-info",
              else: "badge badge-neutral"
            )
          ]}
        >
          <.icon name="hero-information-circle" class="w-4 h-4" /> {@trip_values.current_activity}
        </span>
        <span
          :if={@trip_values.rating_reminder != nil}
          id={"rating-reminder-#{@trip}-id"}
          class={[
            "font-mono",
            if(@trip_values.trip_completed_at == nil,
              do: "badge badge-info",
              else: "badge badge-neutral"
            )
          ]}
        >
          <.icon name="hero-information-circle" class="w-4 h-4" /> "rate this" reminder sent
        </span>
        <span
          :if={@trip_values.rating != nil}
          id={"rating-#{@trip}-id"}
          class={[
            "font-mono",
            if(@trip_values.trip_completed_at == nil,
              do: "badge badge-info",
              else: "badge badge-neutral"
            )
          ]}
        >
          <.icon name="hero-information-circle" class="w-4 h-4" /> rating: {@trip_values.rating}
        </span>
      </p>
    </div>
    """
  end
end
