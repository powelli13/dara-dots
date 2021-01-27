defmodule GameServer.PlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  and start games when two or more players are ready.
  """
  use GenServer
  alias Phoenix.PubSub

  # adds the player to the queue
  def add_player(player_name) do
    GenServer.cast(__MODULE__, {:add_player, player_name})
  end

  @impl GenServer
  def init(_) do
    # TODO necessary if it is registered as the module?
    Registry.register(GameServer.Registry, __MODULE__, %{})

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

      # Generate the new random unique game id
      new_game_id = UUID.uuid4() |> String.split("-") |> hd

      # Inform the lobby channel that the players are in a game together
      # TODO this can be updated to simply use PubSub since the channels
      # automatically subscribe, see RPC game channel and game GenServer
      # Registry.dispatch(GameServerWebRegistry, "rps_lobby:1", fn entries ->
      # for {pid, _} <- entries do
      # send(pid, {:start_game, first_player, second_player, new_game_id})
      # end
      # end)
      PubSub.broadcast(
        GameServer.PubSub,
        # TODO
        "rps_lobby:1",
        {:start_game, first_player, second_player, new_game_id}
      )

      {:noreply, new_queue}
    else
      {:noreply, new_queue}
    end
  end
end
