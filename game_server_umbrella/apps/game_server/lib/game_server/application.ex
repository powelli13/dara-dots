defmodule GameServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: GameServer.PubSub},
      # TODO do I need both a registry and dynamic supervisor?
      # I don't think I need a custom registry
      # Start the ProcessRegistry
      # GameServer.ProcessRegistry,
      # Start the Registry
      {Registry, keys: :unique, name: GameServer.Registry},
      # Start the dynamic supervisor for running games
      GameServer.GameSupervisor,
      # Start the dynamic supervisor for Lip Sync queues
      GameServer.LipSyncQueueSupervisor,
      # Start the server scoreboard
      GameServer.Scoreboard,
      # Start the player queue
      GameServer.PlayerQueue
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: GameServer.Supervisor)
  end
end
