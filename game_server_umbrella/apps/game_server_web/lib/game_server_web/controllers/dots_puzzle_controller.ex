defmodule GameServerWeb.DotsPuzzleController do
  use GameServerWeb, :controller

  def lobby(conn, _params) do
    render(conn, "lobby.html")
  end

  def puzzle(conn, _params) do
    render(conn, "puzzle.html")
  end
end
