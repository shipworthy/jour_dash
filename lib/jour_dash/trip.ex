defmodule JourDash.Trip do
  @moduledoc false

  alias JourDash.Trip.Graph

  @delivery_items [
    "🍔",
    "🍕",
    "🍟",
    "🍣",
    "🍜",
    "🌮",
    "🍓",
    "🍒",
    "🍇",
    "🍎",
    "🍊",
    "🍋",
    "🍌",
    "🍐",
    "🍑",
    "🍆",
    "🥑",
    "🥦",
    "🥬",
    "🥕",
    "🌿",
    "🍅",
    "🍗",
    "🍉",
    "🧁",
    "🍰",
    "🍝",
    "🌯",
    "🥪",
    "🍛",
    "🍲"
  ]

  @delivery_cost_base 300
  @delivery_cost_per_mile 50

  def start(location_pickup \\ nil, location_dropoff \\ nil) do
    location_pickup = location_pickup || :rand.uniform(2) + 2
    location_dropoff = location_dropoff || location_pickup + :rand.uniform(3) + 2
    item_to_deliver = Enum.random(@delivery_items)
    delivery_price_cents = @delivery_cost_base + location_dropoff * @delivery_cost_per_mile

    Graph.new()
    |> Journey.start()
    |> Journey.set(%{
      location_driver: 0,
      location_pickup: location_pickup,
      location_dropoff: location_dropoff,
      item_to_deliver: item_to_deliver,
      delivery_price_cents: delivery_price_cents
    })
  end

  def list() do
    Journey.list_executions(graph_name: Graph.name(), sort_by: [created_at: :desc], limit: 100)
  end
end
