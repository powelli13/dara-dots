defmodule GameServerWeb.DaraDotsGameChannel do
  use GameServerWeb, :channel

  def join("dara_dots_game:" <> game_id, _params, socket) do
    # TODO move this into the queue
    GameServer.DaraDots.DaraDotsGame.start(game_id)

    {:ok, socket}
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
