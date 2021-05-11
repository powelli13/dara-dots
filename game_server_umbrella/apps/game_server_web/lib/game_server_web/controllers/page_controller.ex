defmodule GameServerWeb.PageController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    player_id = get_session(conn, :player_id)

    IO.puts "Player ID from session"
    IO.inspect player_id

    render(conn, "index.html")
  end
end
