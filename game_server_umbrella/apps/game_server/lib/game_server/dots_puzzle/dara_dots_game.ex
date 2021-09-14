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

  defp broadcast_game_state(state) do
    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state}
    )
  end
end
