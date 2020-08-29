defmodule GameServer.PlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  and start games when two or more players are ready.
  """
  use GenServer

  # adds the player to the queue
  def add_player(player_name) do
    GenServer.call(__MODULE__, {:add_player, player_name})
  end

  @impl true
  def init(_) do
    # Erlang language queue is used here
    {:ok, :queue.new()}
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def handle_call({:add_player, player_name}, _from, queue) do
    new_queue = :queue.in(player_name, queue)

    if :queue.len(new_queue) >= 2 do
      {{:value, first_player}, new_queue} = :queue.out(new_queue)
      {{:value, second_player}, new_queue} = :queue.out(new_queue)
      # TODO not sure if this setup is optimal but I'm trying it for now

      # TODO this may work but I don't know how to structure the receiving in the lobby channel process
      #send(from, {:start_game, first_player, second_player})

      # send reply letting caller know the players ready for the game
      {:reply, {:start_game, first_player, second_player}, new_queue}
    else
      # tell caller there is no game to start
      {:reply, {:no_game, :queue.len(new_queue)}, new_queue}
    end
  end
end