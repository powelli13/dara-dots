defmodule GameServer.DaraDots.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.DaraDots.{Board, Coordinate, SquarePiece}

  @broadcast_frequency 70

  def start(id) do
    GenServer.start(__MODULE__, id, name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, id}}}
  end

  @impl GenServer
  def init(game_id) do
    # Distances are represented as percentages for the board to display
    initial_state = %{
      game_id: game_id
    }

    # Setup the initial pieces
    {:ok, board} = Board.new()
    initial_state = Map.put(initial_state, :board, board)

    # Start the regular state broadcasting
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, state) do
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    broadcast_game_state(state)

    {:noreply, state}
  end

  defp broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      dots:
        Enum.map(
          state.board.dot_coords,
          fn coord -> coord |> coord_to_percent end
        ),
      bot_alpha: state.board.bot_linker_alpha.coord |> coord_to_percent,
      bot_beta: state.board.bot_linker_beta.coord |> coord_to_percent,
      top_alpha: state.board.top_linker_alpha.coord |> coord_to_percent,
      top_beta: state.board.top_linker_beta.coord |> coord_to_percent
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end

  defp coord_to_percent(%Coordinate{} = coord) do
    [coord.row, coord.col]
  end
end
