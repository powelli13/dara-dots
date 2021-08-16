defmodule GameServer.PongActiveGames do
  use GenServer
  @moduledoc """
  Keeps track of the active Pong Games to display them in the
  lobby so that other players can view the game.
  """
  # TODO this may be better done as a supervisor over the PongGameSupervisors
  # I will need to do more research
  def init(active_games) do
  end
end