defmodule GameServerWeb.GameController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    render(conn, "rps_lobby.html")
  end
end
