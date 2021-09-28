defmodule GameServer.PongActiveGames do
  use GenServer
  alias GameServer.PongGame

  @moduledoc """
  Keeps track of the active Pong Games to display them in the
  lobby so that other players can view the game.
  """
  # TODO could we use presence for this?
  def add_active_game(game_id) do
    GenServer.cast(__MODULE__, {:add_game, game_id})
  end

  def remove_game(game_id) do
    GenServer.cast(__MODULE__, {:remove_game, game_id})
  end

  def get_active_games() do
    GenServer.call(__MODULE__, :get_games)
  end

  # I will need to do more research
  @impl GenServer
  def init(_) do
    # Using a MapSet in case I want to store more than
    # the game ID eventually
    {:ok, MapSet.new()}
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  def handle_cast({:add_game, game_id}, games) do
    {:noreply, MapSet.put(games, game_id)}
  end

  @impl GenServer
  def handle_cast({:remove_game, game_id}, games) do
    {:noreply, MapSet.delete(games, game_id)}
  end

  @impl GenServer
  def handle_call(:get_games, _sender, games) do
    {
      :reply,
      games
      |> MapSet.to_list()
      |> Enum.map(fn game_id ->
        # TODO make this more robust so it handles when there is no game
        # when the ID is stale this is an unhandled exit
        {
          top_player,
          bot_player
        } = PongGame.get_player_names(game_id)

        {game_id, top_player, bot_player}
      end),
      games
    }
  end
end
