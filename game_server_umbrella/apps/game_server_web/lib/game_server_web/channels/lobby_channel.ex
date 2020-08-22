defmodule GameServerWeb.LobbyChannel do
  use GameServerWeb, :channel

  def join("lobby:" <> lobby_id, _params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{message: message})
    {:noreply, socket}
  end
end