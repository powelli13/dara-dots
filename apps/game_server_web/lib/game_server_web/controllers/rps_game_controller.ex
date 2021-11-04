defmodule GameServerWeb.RpsGameController do
  use GameServerWeb, :controller

  def index(conn, params) do
    case Map.fetch(params, "rps_id") do
      {:ok, _game_id} ->
        render(conn, "index.html")

      :error ->
        redirect(conn, to: Routes.game_path(conn, :lobby))
    end
  end

  def lobby(conn, _params) do
    render(conn, "rps_lobby.html", game_name: "Rock Paper Scissors", lobby_name: "rps")
  end
end
