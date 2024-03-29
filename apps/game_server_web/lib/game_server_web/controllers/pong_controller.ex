defmodule GameServerWeb.PongController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    render(
      conn,
      "pong_lobby.html",
      game_name: "Pong",
      lobby_name: "pong",
      active_games: GameServer.PongActiveGames.get_active_games()
    )
  end

  def spectate(conn, _params) do
    render(conn, "spectate.html")
  end
end
