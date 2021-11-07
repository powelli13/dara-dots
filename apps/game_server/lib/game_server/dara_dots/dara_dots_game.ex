defmodule GameServer.DaraDots.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.DaraDots.{Board, Coordinate}

  @broadcast_frequency 70

  def start(id) do
    GenServer.start(__MODULE__, id, name: via_tuple(id))
  end

  def select_piece(id, piece) do
    GenServer.cast(via_tuple(id), {:select_piece, piece})
  end

  def get_selected_piece(id) do
    GenServer.call(via_tuple(id), :get_selected_piece)
  end

  def submit_move(id, row, col) do
    IO.inspect "submitted a move!!!"
    GenServer.cast(via_tuple(id), {:submit_move, row, col})
  end

  defp via_tuple(id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, id}}}
  end

  @impl GenServer
  def init(game_id) do
    # Distances are represented as percentages for the board to display
    initial_state = %{
      game_id: game_id,
      selected_piece: :none
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

  @impl GenServer
  def handle_cast({:select_piece, piece}, state) do
    # TODO will want to use player IDs and check if they can move
    # which turn is it, etc.
    {:noreply, %{state | selected_piece: piece}}
  end

  @impl GenServer
  def handle_cast({:submit_move, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)
    IO.inspect "!!?!??!? selected piece"
    IO.inspect state.selected_piece

    moved_board = Board.move_linker_no_link(state.board, state.selected_piece, dest_coord)

    {:noreply, %{state | board: moved_board, selected_piece: :none}}
  end

  @impl GenServer
  def handle_call(:get_movable_dots, _, state) do
    {:reply, state.movable_dots, state}
  end

  @impl GenServer
  def handle_call(:get_selected_piece, _, state) do
    {:reply, state.selected_piece, state}
  end

  defp broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      dots:
        Enum.map(
          state.board.dot_coords,
          fn coord -> coord |> Coordinate.to_list() end
        ),
      bot_alpha: state.board.bot_linker_alpha.coord |> Coordinate.to_list(),
      bot_beta: state.board.bot_linker_beta.coord |> Coordinate.to_list(),
      top_alpha: state.board.top_linker_alpha.coord |> Coordinate.to_list(),
      top_beta: state.board.top_linker_beta.coord |> Coordinate.to_list(),
      movable_dots:
        Enum.map(
          Board.get_movable_coords(state.board, state.selected_piece) |> MapSet.to_list(),
          fn coord -> Coordinate.to_list(coord) end
        ),
      runner_pieces:
        Enum.map(
          MapSet.to_list(state.board.runner_pieces),
          fn runner -> Coordinate.to_list(runner.coord) end
        )
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end
end
