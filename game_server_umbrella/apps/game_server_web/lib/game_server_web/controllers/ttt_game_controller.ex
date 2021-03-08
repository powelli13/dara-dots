defmodule GameServerWeb.TttGameController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    # TODO ensure valid game ID
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    render(conn, "ttt_lobby.html")
  end
end
