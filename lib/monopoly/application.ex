defmodule Monopoly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MonopolyWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:monopoly, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Monopoly.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Monopoly.Finch},
      # Start a worker by calling: Monopoly.Worker.start_link(arg)
      # {Monopoly.Worker, arg},
      # Start to serve requests, typically the last entry
      {GameObjects.Game, []},
      MonopolyWeb.Endpoint
    ]

    :ets.new(Game.Store, [:named_table, :public])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Monopoly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MonopolyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
