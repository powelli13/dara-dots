defmodule GameServer.PlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  and start games when two or more players are ready.
  """
  use GenServer

  # adds the player to the queue
  def add_player(player_socket) do
    GenServer.cast(__MODULE__, {:add_player, player_socket})
  end

  @impl GenServer
  def init(_) do
    # Erlang language queue is used here
    {:ok, :queue.new()}
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  def handle_cast({:add_player, player_name}, queue) do
    new_queue = :queue.in(player_name, queue)

    if :queue.len(new_queue) >= 2 do
      {{:value, first_player}, new_queue} = :queue.out(new_queue)
      {{:value, second_player}, new_queue} = :queue.out(new_queue)

      new_game_id = Ecto.UUID.generate()

      # Inform the lobby channel that the players are in a game together
      Registry.dispatch(GameServerWebRegistry, "lobby_channel", fn entries ->
        for {pid, _} <- entries do
          send(pid, {:start_game, first_player, second_player, new_game_id})
        end
      end)

      {:noreply, new_queue}
    else
      # tell caller there is no game to start
      {:noreply, new_queue}
    end
  end
end
