defmodule GameServerWeb.PongController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    render(conn, "pong_lobby.html")
  end
end
