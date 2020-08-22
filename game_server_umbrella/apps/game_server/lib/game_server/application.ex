defmodule GameServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      GameServer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: GameServer.PubSub}
      # Start a worker by calling: GameServer.Worker.start_link(arg)
      # {GameServer.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: GameServer.Supervisor)
  end
end
