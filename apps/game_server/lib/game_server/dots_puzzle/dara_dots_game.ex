defmodule GameServer.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.{Board, Coordinate, Piece}

  @broadcast_frequency 70

  @open_dot " "

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

  # retrieve the coordinates that are accessible to a piece at the given coords
  defp get_movable_coords(coords) do
    # TODO come up with a more elegant way to do this
    # change these to not use percentages, instead use coords
    [x, y] = coord_to_percent(coords)
    offsets = [[0.1, 0], [-0.1, 0], [0, 0.1], [0, -0.1]]

    Enum.map(offsets, fn [ox, oy] -> [x + ox, y + oy] end)
  end

  defp broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      dots:
        Enum.map(
          state.board.dot_coords,
          fn coord -> coord_to_percent_with_open(coord) end
        ),
      circle_coord: state.board.circle_piece.coord |> coord_to_percent,
      circle_movable_coords: get_movable_coords(state.board.circle_piece.coord)
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end

  defp coord_to_percent(%Coordinate{} = coord) do
    [coord.row / 10, coord.col / 10]
  end

  # TODO make the coordinates know if they are open or not
  # move this logic into board.ex as well
  defp coord_to_percent_with_open(%Coordinate{} = coord) do
    [coord.row / 10, coord.col / 10, @open_dot]
  end
end
