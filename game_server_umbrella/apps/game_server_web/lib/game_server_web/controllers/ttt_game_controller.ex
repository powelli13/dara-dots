defmodule GameServerWeb.TttGameController do
  use GameServerWeb, :controller

  def index(conn, params) do
    case Map.fetch(params, "id") do
      {:ok, game_id} ->
        # TODO verify that the game is live?
        render(conn, "index.html")

      :error ->
        redirect(conn, to: Routes.tttgame_path(conn, :lobby))
    end
  end

  def lobby(conn, _params) do
    render(conn, "ttt_lobby.html")
  end
end
