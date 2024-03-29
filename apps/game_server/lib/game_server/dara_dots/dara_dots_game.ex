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

  # TODO write tests for this
  def select_piece(game_id, player_id, piece_string) do
    piece =
      case piece_string do
        "top_alpha" ->
          :top_linker_alpha

        "top_beta" ->
          :top_linker_beta

        "bot_alpha" ->
          :bot_linker_alpha

        "bot_beta" ->
          :bot_linker_beta

        _ ->
          :error
      end

    if piece != :error do
      GenServer.cast(via_tuple(game_id), {:select_piece, player_id, piece})
    end
  end

  def get_full_board(id) do
    GenServer.call(via_tuple(id), :get_full_board)
  end

  def get_pending_actions(id) do
    GenServer.call(via_tuple(id), :get_pending_actions)
  end

  def get_selected_piece(game_id) do
    GenServer.call(via_tuple(game_id), :get_selected_piece)
  end

  def get_current_turn(game_id) do
    GenServer.call(via_tuple(game_id), :get_current_turn)
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

  def confirm_turn_actions(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:confirm_turn_actions, player_id})
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
      bot_player_id: nil,
      pending_actions: %{}
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
    Broadcaster.broadcast_player_specifics(state)
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
  def handle_cast({:select_piece, player_id, piece}, state) do
    if is_player_turn?(state, player_id) &&
         is_player_piece?(state, player_id, piece) do
      {:noreply, %{state | selected_piece: piece}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:submit_move, player_id, row, col}, state) do
    if is_player_turn?(state, player_id) do
      {:ok, dest_coord} = Coordinate.new(row, col)
      # Check if the move is valid

      new_pending_actions =
        save_pending_action(
          state.pending_actions,
          {:move, player_id, state.selected_piece, dest_coord}
        )

      # Generate a new board state with the action,
      # don't yet update current board though
      # Use new boardstate to generate transition animations
      # or ghost piece placement

      # TODO LEFT OFF need to break this board modifying code into confirm turn
      # player_turn = get_player_turn(state, player_id)

      # moved_board =
      # state.board
      # |> Board.move_linker_no_link(player_turn, state.selected_piece, dest_coord)

      # TODO this will clear animations even if the move was illegal
      confirm_player_end_turn(state)

      {:noreply, %{state | selected_piece: :none, pending_actions: new_pending_actions}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:submit_link_move, player_id, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)

    new_pending_actions =
      save_pending_action(
        state.pending_actions,
        {:move_with_link, player_id, state.selected_piece, dest_coord}
      )

    player_turn = get_player_turn(state, player_id)

    moved_board =
      state.board
      |> Board.move_linker_and_link(player_turn, state.selected_piece, dest_coord)

    # TODO this will clear animations even if the move was illegal
    confirm_player_end_turn(state)

    {:noreply, %{state | board: moved_board, selected_piece: :none}}
  end

  @impl GenServer
  def handle_cast({:place_runner, player_id, row, col}, state) do
    if is_player_turn?(state, player_id) do
      {:ok, create_coord} = Coordinate.new(row, col)

      # TODO should we get player turn here
      new_pending_actions =
        save_pending_action(
          state.pending_actions,
          {:place_runner, player_id, create_coord}
        )

      # updated_board =
      # state.board
      # |> Board.place_runner(create_coord)

      {:noreply, %{state | pending_actions: new_pending_actions}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:confirm_turn_actions, player_id}, state) do
    new_state = confirm_player_end_turn(state)

    # TODO animations?
    # This should not be here, the state should only change if confirm player end turn
    # says that it should
    new_board_state = Board.advance_runners(new_state.board)
    new_state = Map.put(new_state, :board, new_board_state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:get_full_board, _, state) do
    {:reply, state.board, state}
  end

  @impl GenServer
  def handle_call(:get_pending_actions, _, state) do
    {:reply, state.pending_actions, state}
  end

  @impl GenServer
  def handle_call(:get_movable_dots, _, state) do
    {:reply, state.movable_dots, state}
  end

  @impl GenServer
  def handle_call(:get_selected_piece, _, state) do
    {:reply, state.selected_piece, state}
  end

  @impl GenServer
  def handle_call(:get_current_turn, _, state) do
    current_turn = Board.get_current_turn(state.board)
    {:reply, current_turn, state}
  end

  # Add a GenServer impl to confirm player turn
  # Play out pending actions in order
  # Update runner pieces
  # Change turn

  # To be expanded when player confirmations are added
  # Right now it is just used to clear the runner paths
  # Just trying to slightly future proof, but this will certainly change
  # Need to incorporate remaining actions logic in this module
  def confirm_player_end_turn(state) do
    Process.send_after(self(), :clear_runner_paths, 1000)

    # only submit if it is their turn
    # only change turn if no more actions to make (enforced in board)
    # error message if they still have pending actions
    # only enable button if there are no more actions to make
    # apply pending actions and actually update board state
    # change turn

    state
  end

  # The is_legal_move? functions should take in a board since they will operate on
  # temporary boards. They should take in a board, use the action tuple to find
  # which legality to check, and then check it using the Board module.
  def is_legal_move?(
        state,
        player_id,
        {:place_runner, player_id, create_coord}
      ) do
    # I think that it is best for all rules validation to happen in the
    # board module. Because there will be non-official, temporary boards
    # for pending actions. So the changes to those boards and how to check
    # will be all self contained in that module and data structure.
    # The Data Dots game module will handle converting messages to actions,
    # storing pending moves, and converting player_ids into positional player
    # references for the Board module.
    player_turn = get_player_turn(state, player_id)

    Board.is_legal_runner_placement?(state.board, player_turn, create_coord)
  end

  # TODO unit test me!
  def is_legal_move?(
        state,
        player_id,
        {:move, player_id, selected_piece, dest_coord}
      ) do
    player_turn = get_player_turn(state, player_id)

    # TODO see comment in board, all rules validation should be in Board
    is_coord_open?(state, dest_coord) &&
      is_players_piece?(state, player_id, selected_piece) &&
      Board.is_legal_move_coord?(state.board, player_turn, selected_piece, dest_coord)
  end

  def is_players_piece?(state, player_id, piece) do
    cond do
      player_id == state.top_player_id ->
        piece == :top_linker_alpha || piece == :top_linker_beta

      player_id == state.bot_player_id ->
        piece == :bot_linker_alpha || piece == :bot_linker_beta

      # Default to false
      true ->
        false
    end
  end

  def is_coord_open?(state, coord) do
    !(Board.node_has_linker?(state.board, coord) ||
        Board.node_has_runner?(state.board, coord))
  end

  defp get_player_turn(state, player_id) do
    cond do
      player_id == state.top_player_id ->
        :top_player

      player_id == state.bot_player_id ->
        :bot_player
    end
  end

  # TODO consider removing these since validation will all happen in the Board
  # These two functions are used because we need to convert
  # the player_id into the player turn used by the board
  def is_player_turn?(state, player_id) do
    player_turn = get_player_turn(state, player_id)
    Board.is_player_turn?(state.board, player_turn)
  end

  def is_player_piece?(state, player_id, piece_key) do
    player_turn = get_player_turn(state, player_id)
    Board.is_players_piece?(player_turn, piece_key)
  end

  def apply_pending_actions(board, pending_actions) do
    # TODO should we have this kicked off by a cast?
    # for each pending action
    # apply the action to create a new board
    # then update the state board
  end

  @doc """
  Digest the action tuple, apply it to create a new board state
  and return that board state.
  """
  def apply_pending_action(board, action_tuple) do
    # TODO I don't think these can be player_id
    case action_tuple do
      {:move, player_id, selected_piece, dest_coord} ->
        Board.move_linker_no_link(board, player_id, selected_piece, dest_coord)

      {:move_with_link, player_id, selected_piece, dest_coord} ->
        Board.move_linker_and_link(board, player_id, selected_piece, dest_coord)

      {:place_runner, _player_id, create_coord} ->
        Board.place_runner(board, create_coord)

      _ ->
        board
    end
  end

  defp save_pending_action(pending_actions, action_tuple) do
    cond do
      !Map.has_key?(pending_actions, 1) ->
        Map.put(pending_actions, 1, action_tuple)

      !Map.has_key?(pending_actions, 2) ->
        Map.put(pending_actions, 2, action_tuple)

      !Map.has_key?(pending_actions, 3) ->
        Map.put(pending_actions, 3, action_tuple)

      # We cannot take any more actions, should we error?
      true ->
        pending_actions
    end
  end
end
