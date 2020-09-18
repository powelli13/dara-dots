defmodule GameServerWeb.GameController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
