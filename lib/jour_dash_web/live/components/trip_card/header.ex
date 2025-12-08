defmodule JourDashWeb.Live.Components.TC.Header do
  @moduledoc false

  use JourDashWeb, :html

  def render(assigns) do
    ~H"""
    <h1 class="mb-2 pb-2 flex items-center">
      <span id={"trip-id-on-card-#{@trip}-id"}>
        <span class="text-xs font-mono border-1 rounded-md p-1 font-light bg-base-100">
          {String.slice(@trip, 0, 12)}
        </span>
      </span>
      <span
        id={"running-status-on-card-#{@trip}-id"}
        class="ml-auto flex items-center gap-2"
      >
        <div class="dropdown dropdown-left inline-block">
          <span class="font-mono badge badge-outline badge-xl badge-success">
            <span class={if @trip_values.trip_completed_at == nil, do: "animate-pulse", else: ""}>
              {@trip_values.item_to_deliver}
            </span>
            <span
              :if={@trip_values.trip_completed_at == nil}
              class="status status-success mx-1 status-lg animate-pulse"
            >
            </span>
            <span
              :if={@trip_values.dropped_off? == true}
              id={"dropped-off-#{@trip}-id"}
              class=""
            >
              📦
            </span>
            <span
              :if={@trip_values.handed_off? == true}
              id={"handed-off-#{@trip}-id"}
              class=""
            >
              💁
            </span>

            <span
              :if={@trip_values.trip_completed_at != nil}
              id={"completed-#{@trip}-id"}
              class=""
            >
              ✅
            </span>
          </span>
        </div>
      </span>
    </h1>
    """
  end
end
