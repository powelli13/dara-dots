defmodule GameServerWeb.LobbyChannel do
  use GameServerWeb, :channel

  def join("lobby:" <> lobby_id, %{"random_id" => random_id}, socket) do
    {:ok, assign(socket, :user_id, random_id)}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{user_id: socket.assigns.user_id, message: message})
    {:noreply, socket}
  end
end