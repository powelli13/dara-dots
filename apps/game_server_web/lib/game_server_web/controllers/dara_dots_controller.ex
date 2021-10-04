defmodule GameServerWeb.DaraDotsController do
  use GameServerWeb, :controller

  def lobby(conn, _params) do
    render(conn, "lobby.html")
  end

  def game(conn, _params) do
    render(conn, "game.html")
  end
end
