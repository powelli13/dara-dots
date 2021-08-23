defmodule GameServerWeb.PongController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    active_games = GameServer.PongActiveGames.get_active_games()

    render(conn, "pong_lobby.html", active_games: active_games)
  end

  def spectate(conn, _params) do
    render(conn, "spectate.html")
  end
end
