defmodule JourDashWeb.Live.Components.TC.ExpandableHistory do
  @moduledoc false

  use JourDashWeb, :html
  require Logger

  def render(assigns) do
    ~H"""
    <div
      id={"trip-card-chevron-#{@trip}-id"}
      phx-click="on_trip_card_chevron_down_click"
      class="absolute bottom-2 right-2 opacity-100 p-2"
    >
      <.icon :if={!@expanded?} name="hero-chevron-down" class="w-6 h-6" />
      <.icon :if={@expanded?} name="hero-chevron-up" class="w-6 h-6" />
    </div>

    <div
      :if={@trip_values.trip_history != nil and @expanded?}
      class="text-sm font-mono border-t-1 my-5 py-4"
    >
      History:
      <%= for %{"node" => node, "timestamp" => timestamp, "value" => value} <- @trip_values.trip_history |> Enum.reverse() do %>
        <div class="text-xs my-1 font-mono">
          <span class="text-info">
            {JourDash.Helpers.to_datetime_string_compact(timestamp, @time_zone)}
          </span>
          {node}: <span class="text-info">{value}</span>
        </div>
      <% end %>
    </div>

    <details
      :if={@introspection != nil and @expanded?}
      id={"trip-card-introspection-#{@trip}-id"}
      class="group border-t-1 my-3 pt-3"
    >
      <summary class="cursor-pointer flex items-center gap-2 text-sm font-mono list-none [&::-webkit-details-marker]:hidden">
        <span>Introspection</span>
        <.icon name="hero-chevron-down" class="size-4 group-open:hidden" />
        <.icon name="hero-chevron-up" class="size-4 hidden group-open:block" />
      </summary>
      <pre class="whitespace-pre-wrap break-words mt-2 text-xs">iex&gt; Journey.Tools.introspect("{@trip}") |&gt; IO.puts()
    {@introspection}</pre>
    </details>
    """
  end
end
