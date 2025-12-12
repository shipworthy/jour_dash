defmodule JourDashWeb.Live.Components.About do
  use JourDashWeb, :html

  @moduledoc false

  def render(assigns) do
    ~H"""
    <div id="about-service-id" class="mx-auto max-w-2xl flex justify-center px-3">
      <div class="text-sm justify-center font-mono border-1 rounded-md my-1 p-4 bg-base-100 w-full">
        <div class="py-1">
          This play-demo service is built with <a
            class="link link-primary"
            target="_blank"
            href="https://elixir-lang.org/"
          >
            Elixir
          </a>, <a
            class="link link-primary"
            target="_blank"
            href="https://www.phoenixframework.org/"
          >Phoenix LiveView</a>, and <a
            class="link link-primary"
            target="_blank"
            href="https://hexdocs.pm/journey/"
          >Journey</a>'s reactive durable workflows and analytics.
        </div>
        <div class="py-1">
          JourDash source is available on Github:
          <a
            class="link link-primary"
            target="_blank"
            href="https://github.com/shipworthy/jour_dash"
          >
            repo
          </a>
          |
          <a
            class="link link-primary"
            target="_blank"
            href="https://github.com/shipworthy/jour_dash/blob/main/lib/jour_dash/trip/graph.ex"
          >
            graph
          </a>
        </div>
        <div class="py-1">
          Let's deliver some snacks! <span class="text-lg">🍓</span>
        </div>
      </div>
    </div>
    """
  end
end
