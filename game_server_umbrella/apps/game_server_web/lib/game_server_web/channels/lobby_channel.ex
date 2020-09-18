defmodule GameServerWeb.LobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.Scoreboard
  alias GameServer.PlayerQueue
  alias GameServer.GameSupervisor
  alias GameServer.RockPaperScissors

  # Register the Channel process so that it
  # can receive updates from the player queue
  def start_link(opts) do
    IO.puts "HI THERE FROM start_link!!!"
    Registry.register(GameServerWebRegistry, "lobby_channel", nil)

    GenServer.start_link(
      __MODULE__,
      opts
    )
  end

  def join("lobby:" <> _lobby_id, %{"username" => username}, socket) do
    #TODO probably bad practice just trying to make things work
    Registry.register(GameServerWebRegistry, "lobby_channel", nil)

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

  # Handle messages from the queue indicating that a game is ready
  def handle_info({:start_game, player_one, player_two, new_game_id}, socket) do
    # Start the game and add players
    start_game_pid = GameSupervisor.find_game(new_game_id)

    # TODO this can be improved
    if socket.assigns.username == player_one ||
      socket.assigns.username == player_two do

      RockPaperScissors.add_player(start_game_pid, socket.assigns.username)
      push(socket, "game_started", %{username: socket.assigns.username, game_id: new_game_id})
    end

    {:noreply, socket}
  end

  # Invoked when the queue sends that people are ready to play
  def handle_in("join_queue", _, socket) do
    PlayerQueue.add_player(socket.assigns.username)

    {:noreply, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end

  # TODO just testing things
  def handle_in("win_test", %{"winner" => _phrase}, socket) do
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
