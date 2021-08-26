defmodule GameServer.PongPlayerQueue do
  @moduledoc """
  Queue used to monitor players that are ready to play
  a game of Pong. Starts a game and broadcasts that it
  is ready when two or more players are ready.
  """
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.PongGameSupervisor
  alias GameServer.PongGame

  def add_player(player_id, player_name) do
    GenServer.cast(__MODULE__, {:add_player, player_id, player_name})
  end

  def remove_player(player_id) do
    GenServer.cast(__MODULE__, {:remove_player, player_id})
  end

  def get_queue_size() do
    GenServer.call(__MODULE__, :get_queue_size)
  end

  @impl GenServer
  def init(_) do
    {:ok, MapSet.new()}
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  def handle_cast({:add_player, player_id, player_name}, map_set) do
    {
      :noreply,
      unless already_in_queue?(map_set, player_id) do
        # check for starting the game
        check_start_game(
          MapSet.put(
            map_set,
            {
              player_id,
              player_name,
              System.system_time(:second)
            }
          )
        )
      else
        map_set
      end
    }
  end

  @impl GenServer
  def handle_cast({:remove_player, player_id}, map_set) do
    {:noreply, map_set |> remove_player(player_id)}
  end

  @impl GenServer
  def handle_call(:get_queue_size, _caller, map_set) do
    {:reply, MapSet.size(map_set), map_set}
  end

  defp get_two_earliest_player_ids_and_names(map_set) do
    [{first_id, first_name, _}, {second_id, second_name, _}] =
      map_set
      |> MapSet.to_list()
      |> Enum.sort(fn {_, _, a_time}, {_, _, b_time} -> a_time <= b_time end)
      |> Enum.take(2)

    {{first_id, first_name}, {second_id, second_name}}
  end

  defp already_in_queue?(map_set, new_id) do
    map_set
    |> MapSet.to_list()
    |> Enum.map(fn {n, _, _} -> n end)
    |> Enum.any?(fn n -> n == new_id end)
  end

  defp check_start_game(map_set) do
    if MapSet.size(map_set) >= 2 do
      # grab two players in queue longest
      {
        {first_player_id, first_player_name},
        {second_player_id, second_player_name}
      } = get_two_earliest_player_ids_and_names(map_set)

      # delete those players from the map set
      new_map_set =
        map_set
        |> remove_player(first_player_id)
        |> remove_player(second_player_id)

      # start new game with player names
      # Generate the new random unique game id
      new_game_id = UUID.uuid4() |> String.split("-") |> hd

      # Start game GenServer and add players
      #_start_game_pid = PongGameSupervisor.find_or_create_game(new_game_id)
      # TODO The supervisor is unneeded because the game will start itself thanks to via_tuple
      # Also we don't need resiliency for game states
      IO.puts "!!!!!!!!!!!!!!!!!!!! Attempting to start pong game without linking"
      {:ok, _pid} = PongGame.start(new_game_id)
      IO.puts "????????????????????? after the attempt"

      r = :rand.uniform()

      cond do
        r > 0.5 ->
          PongGame.set_top_paddle_player(new_game_id, first_player_id, first_player_name)
          PongGame.set_bot_paddle_player(new_game_id, second_player_id, second_player_name)

        true ->
          PongGame.set_top_paddle_player(new_game_id, second_player_id, second_player_name)
          PongGame.set_bot_paddle_player(new_game_id, first_player_id, first_player_name)
      end

      # Inform the lobby channels that the players are in a game together
      # The lobby name here must align with
      # what is used on the lobby's template
      PubSub.broadcast(
        GameServer.PubSub,
        "lobby_chat:pong",
        {:start_game, first_player_id, second_player_id, new_game_id}
      )

      new_map_set
    else
      map_set
    end
  end

  defp remove_player(map_set, deleted_id) do
    map_set
    |> MapSet.to_list()
    |> Enum.filter(fn {n, _, _} -> n != deleted_id end)
    |> MapSet.new()
  end
end
