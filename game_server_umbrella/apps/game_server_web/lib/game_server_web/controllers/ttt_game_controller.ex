defmodule GameServerWeb.TttGameController do
  use GameServerWeb, :controller

  def index(conn, params) do
    case Map.fetch(params, "id") do
      {:ok, _game_id} ->
        # TODO verify that the game is live?
        # TODO verify that the player attempting to join is a player of that game?
        render(conn, "index.html")

      :error ->
        redirect(conn, to: Routes.ttt_game_path(conn, :lobby))
    end
  end

  def lobby(conn, _params) do
    render(conn, "ttt_lobby.html" game_name: "Tic Tac Toe", lobby_name: "ttt")
    # TODO find a way to make the generic lobby be in a different folder
    #render(conn, "generic_lobby.html", game_name: "Tic Tac Toe Test!!", lobby_name: "ttt")
  end
end
