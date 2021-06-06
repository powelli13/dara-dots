defmodule GameServer.PongPlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  a game of Pong. Starts a game and broadcasts that it
  is ready when two or more players are ready.
  """
  use GenServer
end
