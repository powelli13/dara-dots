defmodule GameServerWeb.DaraDotsGameChannel do
  use GameServerWeb, :channel

  def join("dara_dots_game:" <> game_id, _params, socket) do
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

  def handle_in("submit_move", %{"row" => row, "col" => col}, socket) do
    GameServer.DaraDots.DaraDotsGame.submit_move(
      socket.assigns[:game_id],
      socket.assigns[:player_id],
      row,
      col
    )

    {:noreply, socket}
  end

  def handle_in("submit_link_move", %{"row" => row, "col" => col}, socket) do
    GameServer.DaraDots.DaraDotsGame.submit_link_move(
      socket.assigns[:game_id],
      socket.assigns[:player_id],
      row,
      col
    )

    {:noreply, socket}
  end

  def handle_in("place_runner", %{"row" => row, "col" => col}, socket) do
    GameServer.DaraDots.DaraDotsGame.place_runner(socket.assigns[:game_id], row, col)

    {:noreply, socket}
  end

  def handle_info({:new_game_state, game_state}, socket) do
    # Determine pieces of state that are unique to the player
    player_message = game_state[socket.assigns.player_id]

    push(
      socket,
      "game_state",
      %{
        dots: game_state.dots,
        topAlphaCoord: game_state.top_alpha,
        topBetaCoord: game_state.top_beta,
        botAlphaCoord: game_state.bot_alpha,
        botBetaCoord: game_state.bot_beta,
        topPlayerScore: game_state.top_player_score,
        botPlayerScore: game_state.bot_player_score,
        movableDots: game_state.movable_dots,
        linkableDots: game_state.linkable_dots,
        runnerPieces: game_state.runner_pieces,
        links: game_state.links,
        playerMessage: player_message,
        currentTurn: game_state.current_turn
      }
    )

    {:noreply, socket}
  end
end
