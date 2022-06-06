defmodule GameServer.DaraDots.DaraDotsGame do
  use GenServer
  alias GameServer.DaraDots.{Board, Coordinate, Broadcaster}

  # I was thinking about this and it may be unnecessarily fast for the turn
  # based nature of the game. Consider changing broadcast frequency, or
  # perhaps only broadcasting parts of updates at once.
  @broadcast_frequency 250

  def start(game_id) do
    GenServer.start(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def add_player(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:add_player, player_id})
  end

  def select_piece(game_id, piece) do
    GenServer.cast(via_tuple(game_id), {:select_piece, piece})
  end

  def get_full_board(id) do
    GenServer.call(via_tuple(id), :get_full_board)
  end

  def get_selected_piece(game_id) do
    GenServer.call(via_tuple(game_id), :get_selected_piece)
  end

  def submit_move(game_id, player_id, row, col) do
    GenServer.cast(via_tuple(game_id), {:submit_move, player_id, row, col})
  end

  def submit_link_move(game_id, player_id, row, col) do
    GenServer.cast(via_tuple(game_id), {:submit_link_move, player_id, row, col})
  end

  def place_runner(game_id, player_id, row, col) do
    GenServer.cast(via_tuple(game_id), {:place_runner, player_id, row, col})
  end

  defp via_tuple(game_id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, game_id}}}
  end

  @impl GenServer
  def init(game_id) do
    # Distances are represented as percentages for the board to display
    initial_state = %{
      game_id: game_id,
      selected_piece: :none,
      top_player_id: nil,
      bot_player_id: nil
    }

    # Setup the initial pieces
    {:ok, board} = Board.new()
    initial_state = Map.put(initial_state, :board, board)

    # Store pending actions on the game
    # apply them as appropriate when broadcasting the state
    # only to the player whose turn it is.
    # Store all the info relevant to the move in the pending actions
    # list or map, later pass that info into the board.
    # Then create a secondary board for broadcasting
    # with the pending move applied.
    # Be sure to only store pending moves if it is the current players turn.
    # On end of turn confirmation apply all pending moves to the actual 
    # board state.
    # Also allow for clearing pending moves.

    # Start the regular state broadcasting
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, state) do
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    Broadcaster.broadcast_game_state(state)
    Broadcaster.broadcast_runner_paths(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:clear_runner_paths, state) do
    no_animations_board = Board.clear_runner_animate_paths(state.board)

    {:noreply, %{state | board: no_animations_board}}
  end

  @impl GenServer
  def handle_cast({:add_player, player_id}, state) do
    added_state =
      cond do
        state.top_player_id == nil -> %{state | top_player_id: player_id}
        state.bot_player_id == nil -> %{state | bot_player_id: player_id}
        true -> state
      end

    {:noreply, added_state}
  end

  @impl GenServer
  def handle_cast({:select_piece, piece}, state) do
    {:noreply, %{state | selected_piece: piece}}
  end

  @impl GenServer
  def handle_cast({:submit_move, player_id, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)
    player_turn = get_player_turn(state, player_id)

    moved_board =
      state.board
      |> Board.move_linker_no_link(player_turn, state.selected_piece, dest_coord)

    # TODO this will clear animations even if the move was illegal
    confirm_player_end_turn(state)
    {:noreply, %{state | board: moved_board, selected_piece: :none}}
  end

  @impl GenServer
  def handle_cast({:submit_link_move, player_id, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)
    player_turn = get_player_turn(state, player_id)

    moved_board =
      state.board
      |> Board.move_linker_and_link(player_turn, state.selected_piece, dest_coord)

    # TODO this will clear animations even if the move was illegal
    confirm_player_end_turn(state)
    {:noreply, %{state | board: moved_board, selected_piece: :none}}
  end

  @impl GenServer
  def handle_cast({:place_runner, _player_id, row, col}, state) do
    {:ok, create_coord} = Coordinate.new(row, col)

    updated_board =
      state.board
      |> Board.place_runner(create_coord)

    {:noreply, %{state | board: updated_board}}
  end

  @impl GenServer
  def handle_call(:get_full_board, _, state) do
    {:reply, state.board, state}
  end

  @impl GenServer
  def handle_call(:get_movable_dots, _, state) do
    {:reply, state.movable_dots, state}
  end

  @impl GenServer
  def handle_call(:get_selected_piece, _, state) do
    {:reply, state.selected_piece, state}
  end

  # To be expanded when player confirmations are added
  # Right now it is just used to clear the runner paths
  # Just trying to slightly future proof, but this will certainly change
  # Need to incorporate remaining actions logic in this module
  def confirm_player_end_turn(state) do
    Process.send_after(self(), :clear_runner_paths, 1000)

    state
  end

  # Returns true if it is the turn of the player
  # attempting to move, otherwise false
  def is_players_turn?(state, player_id) do
    cond do
      player_id == state.top_player_id && Board.is_top_turn?(state.board) ->
        true

      player_id == state.bot_player_id && Board.is_bot_turn?(state.board) ->
        true

      # Default condition is false since it was not the submitted player's turn
      true ->
        false
    end
  end

  def get_player_turn(state, player_id) do
    cond do
      player_id == state.top_player_id ->
        :top_player

      player_id == state.bot_player_id ->
        :bot_player
    end
  end
end
