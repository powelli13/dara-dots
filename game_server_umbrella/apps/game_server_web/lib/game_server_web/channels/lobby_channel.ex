defmodule GameServerWeb.LobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.Scoreboard
  alias GameServer.PlayerQueue

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

  # Invoked when the queue sends that people are ready to play
  def handle_in("join_queue", _, socket) do
    case PlayerQueue.add_player(socket.assigns.username) do
      {:start_game, first_player, second_player} ->
        # TODO may want to put socket ids in queue to?
        # really I think this should be pushed just to the sockets concerned
        # with their game starting
        broadcast!(
          socket,
          "new_msg",
          %{username: "Admin", message: "Game started between #{first_player} and #{second_player}"})

      :no_game ->
        nil
    end

    {:noreply, socket}
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