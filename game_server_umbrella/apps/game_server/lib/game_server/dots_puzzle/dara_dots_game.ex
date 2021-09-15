defmodule GameServer.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.Coordinate

  @broadcast_frequency 70

  @open_dot " "
  @circle_piece "C"

  def start(id) do
    GenServer.start(__MODULE__, id, name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, id}}}
  end

  @impl GenServer
  def init(game_id) do
    # Start the regular state broadcasting
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    # Distances are represented as percentages for the board to display
    initial_state = %{
      game_id: game_id,
      dots: build_dots_board(),
      # TODO use coordinates internally and transform when broadcasting
      # circle_coord: Coordinate.new(2, 2)
      circle_coord: [0.2, 0.2]
    }

    {:ok, initial_state}
  end

  defp build_dots_board() do
    Enum.map(1..9, fn n -> Enum.map(1..9, fn i -> {n / 10, i / 10} end) end)
    |> List.flatten()
    |> Enum.map(fn {row, col} -> [row, col, @open_dot] end)
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
    # change these to no use percentages, instead use coords
    [x, y] = coords
    offsets = [[0.1, 0], [-0.1, 0], [0, 0.1], [0, -0.1]]

    Enum.map(offsets, fn [ox, oy] -> [x + ox, y + oy] end)
  end

  defp broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      dots: state.dots,
      circle_coord: state.circle_coord,
      circle_movable_coords: get_movable_coords(state.circle_coord)
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end
end
