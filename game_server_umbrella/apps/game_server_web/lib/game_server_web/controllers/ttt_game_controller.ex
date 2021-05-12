defmodule GameServerWeb.TttGameController do
  use GameServerWeb, :controller

  def index(conn, params) do
    case Map.fetch(params, "ttt_id") do
      {:ok, game_id} ->
        # TODO verify that the game is live?
        # TODO verify that the player attempting to join is a player of that game?
        render(conn, "index.html")

      :error ->
        redirect(conn, to: Routes.tttgame_path(conn, :lobby))
    end
  end

  def lobby(conn, _params) do
    render(conn, "ttt_lobby.html")
  end
end
