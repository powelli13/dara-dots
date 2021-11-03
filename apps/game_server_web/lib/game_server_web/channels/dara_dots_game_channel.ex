defmodule GameServerWeb.DaraDotsGameChannel do
  use GameServerWeb, :channel

  def join("dara_dots_game:" <> game_id, _params, socket) do
    # TODO move this into the queue
    # put Player ID on the socket.assigns
    GameServer.DaraDots.DaraDotsGame.start(game_id)

    {:ok, socket |> assign(:game_id, game_id)}
  end

  def handle_in("select_piece", %{"piece" => piece}, socket) do
    piece_to_select =
      case piece do
        "top_alpha" ->
          :top_linker_alpha

        "top_beta" ->
          :top_linker_beta

        "bot_alpha" ->
          :bot_linker_alpha

        "bot_beta" ->
          :bot_linker_beta
      end

    GameServer.DaraDots.DaraDotsGame.select_piece(socket.assigns[:game_id], piece_to_select)

    {:noreply, socket}
  end

  def handle_info({:new_game_state, game_state}, socket) do
    push(
      socket,
      "game_state",
      %{
        dots: game_state.dots,
        topAlphaCoord: game_state.top_alpha,
        topBetaCoord: game_state.top_beta,
        botAlphaCoord: game_state.bot_alpha,
        botBetaCoord: game_state.bot_beta,
        movableDots: game_state.movable_dots,
        runnerPieces: game_state.runner_pieces
      }
    )

    {:noreply, socket}
  end
end
