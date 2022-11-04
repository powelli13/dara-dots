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

    GameServer.DaraDots.DaraDotsGame.select_piece(
      socket.assigns[:game_id],
      socket.assigns[:player_id],
      piece_to_select
    )

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
    GameServer.DaraDots.DaraDotsGame.place_runner(
      socket.assigns[:game_id],
      socket.assigns[:player_id],
      row,
      col
    )

    {:noreply, socket}
  end

  def handle_in("confirm_turn_actions", _, socket) do
    GameServer.DaraDots.DaraDotsGame.confirm_turn_actions(
      socket.assigns[:game_id],
      socket.assigns[:player_id]
    )
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
        topPlayerScore: game_state.top_player_score,
        botPlayerScore: game_state.bot_player_score,
        movableDots: game_state.movable_dots,
        linkableDots: game_state.linkable_dots,
        runnerPieces: game_state.runner_pieces,
        links: game_state.links,
        currentTurn: game_state.current_turn,
        readyPendingActions: game_state.ready_pending_actions
      }
    )

    {:noreply, socket}
  end

  def handle_info({:player_specific_state, game_state}, socket) do
    # Determine pieces of state that are unique to the player
    # Could we make this handle only the state that matches the player id?
    # and broadcast twice from the Broadcaster?
    player_state = game_state[socket.assigns.player_id]

    # TODO move highlightable nodes and pending actions to player state
    push(
      socket,
      "player_state",
      %{
        isYourTurn: player_state.is_your_turn
      }
    )

    {:noreply, socket}
  end

  def handle_info({:new_runner_paths, paths}, socket) do
    push(
      socket,
      "runner_paths",
      %{
        paths: paths
      }
    )

    {:noreply, socket}
  end
end
