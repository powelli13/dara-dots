defmodule GameServer.PlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  and start games when two or more players are ready.
  """
  use GenServer

  # adds the player to the queue
  def add_player(player_name) do
    GenServer.cast(__MODULE__, {:add_player, player_name})
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
  def handle_cast({:add_player, player_name}, queue) do
    new_queue = :queue.in(player_name, queue)

    if :queue.len(new_queue) >= 2 do
      {{:value, first_player}, new_queue} = :queue.out(new_queue)
      {{:value, second_player}, new_queue} = :queue.out(new_queue)
      # TODO send top two player names into a new game

      # i'm not sure if i can or should send events (such as game ready)
      # to the LobbyChannel
      # it may make sense to have game:#id channels for each game
      # the id could be passed in the route and then the page could 
      # join the channel which would act as the stateful game
    end

    {:noreply, :queue.in(player_name, new_queue)}
  end
end