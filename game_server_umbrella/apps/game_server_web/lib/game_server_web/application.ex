defmodule GameServerWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      GameServerWeb.Telemetry,
      # Add channel presence
      GameServerWeb.Presence,
      # Start the Endpoint (http/https)
      GameServerWeb.Endpoint,
      # Start the Registry so that process can use
      # it for PubSub
      {Registry, keys: :duplicate, name: GameServerWebRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameServerWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GameServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
