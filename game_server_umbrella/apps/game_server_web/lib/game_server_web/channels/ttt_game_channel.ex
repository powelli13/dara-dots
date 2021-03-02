defmodule GameServerWeb.TttGameChannel do
  use GameServerWeb, :channel

  def join("ttt_game" <> lobby_id, _, socket) do
    {:ok, socket}
  end

  def handle_in("test_echo", _, socket) do
    broadcast!(socket, "test_echo", %{test: "hi from the server!"})
    {:noreply, socket}
  end
end
