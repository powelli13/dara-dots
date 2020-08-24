defmodule GameServerWeb.LobbyChannel do
  use GameServerWeb, :channel

  def join("lobby:" <> lobby_id, %{"username" => username}, socket) do
    {:ok, assign(socket, :username, username)}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end
end