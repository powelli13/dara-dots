defmodule GameServerWeb.LobbyChatChannel do
  @moduledoc """
  Channel used to handle the chat for the various
  lobbies.
  """
  use GameServerWeb, :channel
  # alias GameServer.PongGame

  def join("lobby_chat:" <> lobby_name, %{"username" => username}, socket) do
    socket =
      socket
      |> assign(:username, username)
      |> assign(:lobby_name, lobby_name)

    {:ok, socket}
  end

  # TODO generic queue joining based 
  # should set which queue module to join based on lobby_name

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(
      socket,
      "new_msg",
      %{
        username: socket.assigns.username,
        message: message
      }
    )

    {:noreply, socket}
  end
end
