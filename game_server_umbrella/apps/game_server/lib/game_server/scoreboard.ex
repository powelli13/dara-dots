defmodule GameServer.Scoreboard do
  @moduledoc """
  GenServer used to hold the state of current players
  on the server's wins, losses and draws.
  """
  use GenServer

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  # Client methods
  def report_win(name) do
    GenServer.cast(__MODULE__, {:report_win, name})
  end

  def get_scores() do
    GenServer.call(__MODULE__, :get_scores)
  end

  # Callback implementations
  @impl true
  def init(_) do
    # Initial state is a simply map of player name to wins
    # this should probably be updated later on to use a 
    # struct or something to hold more info
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:report_win, player_name}, player_scores) do
    updated_scores =
      case Map.get(player_scores, player_name) do
        # First report win for that player
        nil ->
          Map.put(player_scores, player_name, 1)

        # Increment existing player's score
        score ->
          Map.put(player_scores, player_name, score + 1)
      end

    {:noreply, updated_scores}
  end

  @impl true
  def handle_call(:get_scores, _from, player_scores) do
    # Transform the scores map into a list of {name, score} tuples.
    # Seems unnecessary but some transformation may be necessary here.
    scores_list =
      Enum.map(
        player_scores,
        fn {k, v} -> {k, v} end
      )

    {:reply, scores_list, player_scores}
  end
end
