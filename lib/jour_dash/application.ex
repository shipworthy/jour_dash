defmodule JourDash.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JourDashWeb.Telemetry,
      JourDash.Repo,
      {DNSCluster, query: Application.get_env(:jour_dash, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JourDash.PubSub},
      # Start a worker by calling: JourDash.Worker.start_link(arg)
      # {JourDash.Worker, arg},
      # Start to serve requests, typically the last entry
      JourDashWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JourDash.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JourDashWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
