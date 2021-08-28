defmodule GameServer.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub

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
    # Start the regular state broadcasting
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    # Distances are represented as percentages for the board to display
    initial_state = %{
      game_id: game_id,
      dots: [
        [0.5, 0.5, @open_dot],
        [0.4, 0.5, @open_dot],
        [0.3, 0.5, @open_dot],
        [0.6, 0.5, @open_dot],
        [0.7, 0.5, @open_dot],
        [0.5, 0.4, @open_dot],
        [0.5, 0.3, @open_dot],
        [0.5, 0.6, @open_dot]
      ]
    }

    {:ok, initial_state}
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
