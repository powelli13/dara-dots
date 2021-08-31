defmodule GameServerWeb.DaraDotsGameChannel do
  use GameServerWeb, :channel

  def join("dara_dots_game:" <> game_id, _params, socket) do
    # TODO move this into the queue
    GameServer.DaraDotsGame.start(game_id)

    {:ok, socket}
  end

  def handle_info({:new_game_state, game_state}, socket) do
    push(
      socket,
      "game_state",
      %{
        dots: game_state.dots
      }
    )

    {:noreply, socket}
  end
end