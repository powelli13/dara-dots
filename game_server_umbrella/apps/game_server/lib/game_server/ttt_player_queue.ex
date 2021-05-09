defmodule GameServer.TttPlayerQueue do
  # TODO make an abstract re-usable module for queues?
  @moduledoc """
  Queue used to monitor players that are ready to play
  and start Tic Tac Toe games when two or more players are ready.
  """
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.TttGameSupervisor
  alias GameServer.TicTacToe

  # adds the player to the queue
  def add_player(player_name) do
    GenServer.cast(__MODULE__, {:add_player, player_name})
  end

  @impl GenServer
  def init(_) do
    # TODO necessary if it is registered as the module?
    Registry.register(GameServer.Registry, __MODULE__, %{})

    {:ok, MapSet.new()}
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  # TODO update this to use server assigned GUIDs to identify players
  def handle_cast({:add_player, player_name}, map_set) do
    updated_map_set =
      unless already_in_queue?(map_set, player_name) do
        new_map_set = MapSet.put(map_set, {player_name, System.system_time(:second)})

        # check for starting the game
        check_start_game(new_map_set)
      else
        map_set
      end

    {:noreply, updated_map_set}
  end

  defp get_two_earliest_player_names(map_set) do
    [{first, _}, {second, _}] =
      map_set
      |> MapSet.to_list()
      |> Enum.sort(fn {_, a_time}, {_, b_time} -> a_time <= b_time end)
      |> Enum.take(2)

    {first, second}
  end

  defp already_in_queue?(map_set, new_name) do
    map_set
    |> MapSet.to_list()
    |> Enum.map(fn {n, _} -> n end)
    |> Enum.any?(fn n -> n == new_name end)
  end

  defp check_start_game(map_set) do
    if MapSet.size(map_set) >= 2 do
      # grab two players in queue longest
      {first_player, second_player} = get_two_earliest_player_names(map_set)

      # delete those players from the map set
      new_map_set =
        map_set
        |> remove_player(first_player)
        |> remove_player(second_player)

      # start new game with player names
      # Generate the new random unique game id
      new_game_id = UUID.uuid4() |> String.split("-") |> hd

      # Start game GenServer and add players
      start_game_pid = TttGameSupervisor.find_game(new_game_id)

      r = :rand.uniform()

      cond do
        r > 0.5 ->
          TicTacToe.set_circle_player(start_game_pid, first_player)
          TicTacToe.set_cross_player(start_game_pid, second_player)

        true ->
          TicTacToe.set_circle_player(start_game_pid, second_player)
          TicTacToe.set_cross_player(start_game_pid, first_player)
      end

      # Inform the lobby channels that the players are in a game together
      PubSub.broadcast(
        GameServer.PubSub,
        # TODO
        "ttt_lobby:1",
        {:start_game, first_player, second_player, new_game_id}
      )

      new_map_set
    else
      map_set
    end
  end

  defp remove_player(map_set, deleted_name) do
    map_set
    |> MapSet.to_list()
    |> Enum.filter(fn {n, _} -> n != deleted_name end)
    |> MapSet.new()
  end
end
