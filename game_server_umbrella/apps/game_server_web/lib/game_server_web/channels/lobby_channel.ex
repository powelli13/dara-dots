@moduledoc """
Channel used to facilitate the chatting in the game Lobby.
"""
defmodule GameServerWeb.LobbyChannel do
  use GameServerWeb, :channel
  alias GameServerWeb.Presence

  def join("lobby:" <> lobby_id, %{"username" => username}, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :username, username)}
  end

  # Used to setup channel presence after a user joins.
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.username, %{})

    # TODO put the score board info on the presence?
    # also add some way to trivially generate wins from the front end to test

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end
end