defmodule GameServerWeb.LobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.Scoreboard

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

  # Receive updates from the game state?
  def handle_info() do
    
    {}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end

  # TODO just testing things
  def handle_in("win_test", %{"winner" => phrase}, socket) do
    Scoreboard.report_win(socket.assigns.username)
    score_message = Scoreboard.get_scores()
      |> Enum.into([], fn {name, score} -> "#{name} has #{score} wins" end)
      |> Enum.join(", ")

    broadcast!(
      socket, 
      "win_test", 
      %{username: "Admin", message: "#{socket.assigns.username} has won!"})

    broadcast!(
      socket,
      "win_test",
      %{username: "Admin", message: "Current scores: #{score_message}"}
    )
    {:noreply, socket}
  end
end