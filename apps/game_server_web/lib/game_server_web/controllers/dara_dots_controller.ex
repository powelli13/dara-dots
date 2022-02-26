defmodule GameServerWeb.DaraDotsController do
  use GameServerWeb, :controller

  def lobby(conn, _params) do
    render(conn, "lobby.html")
  end

  def game(conn, params) do
    case Map.fetch(params, "id") do
      {:ok, _game_id} ->
        # TODO verify that the game is live?
        # TODO verify that the player attempting to join is a player of that game?
        render(conn, "game.html")

      :error ->
        redirect(conn, to: Routes.dara_dots_path(conn, :lobby))
    end
  end
end
