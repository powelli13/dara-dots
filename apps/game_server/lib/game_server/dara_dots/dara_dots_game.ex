defmodule GameServer.DaraDots.DaraDotsGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.DaraDots.{Board, Coordinate}

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
  def handle_cast({:submit_move, _player_id, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)

    moved_board =
      state.board
      |> Board.move_linker_no_link(state.selected_piece, dest_coord)
      |> Board.advance_runners()

    {:noreply, %{state | board: moved_board, selected_piece: :none}}
  end

  @impl GenServer
  def handle_cast({:submit_link_move, _player_id, row, col}, state) do
    {:ok, dest_coord} = Coordinate.new(row, col)

    moved_board =
      state.board
      |> Board.move_linker_and_link(state.selected_piece, dest_coord)
      |> Board.advance_runners()

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

  # Returns true if it is the turn of the player
  # attempting to move, otherwise false
  defp is_players_turn?(state, player_id) do
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

  defp broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      :dots =>
        Enum.map(
          state.board.dot_coords,
          fn coord -> coord |> Coordinate.to_list() end
        ),
      :bot_alpha => state.board.bot_linker_alpha.coord |> Coordinate.to_list(),
      :bot_beta => state.board.bot_linker_beta.coord |> Coordinate.to_list(),
      :top_alpha => state.board.top_linker_alpha.coord |> Coordinate.to_list(),
      :top_beta => state.board.top_linker_beta.coord |> Coordinate.to_list(),
      :top_player_score => state.board.top_player_score,
      :bot_player_score => state.board.bot_player_score,
      :movable_dots =>
        Enum.map(
          Board.get_movable_coords(state.board, state.selected_piece) |> MapSet.to_list(),
          fn coord -> Coordinate.to_list(coord) end
        ),
      :linkable_dots =>
        Enum.map(
          Board.get_linkable_coords(state.board, state.selected_piece) |> MapSet.to_list(),
          fn coord -> Coordinate.to_list(coord) end
        ),
      :runner_pieces =>
        Enum.map(
          state.board.runner_pieces,
          fn {_ix, runner} ->
            %{coords: Coordinate.to_list(runner.coord), facing: to_string(runner.facing)}
          end
        ),
      # TODO does it matter if the links are not tied to specific linkers?
      # I was thinking about this more the other day and a visual indicator
      # may be nice to have. That way the user will know which of their links
      # will go away if they make a new link
      :links =>
        Board.get_all_link_coords(state.board)
        |> Enum.map(fn coord_map_set ->
          coord_map_set
          |> MapSet.to_list()
          |> Enum.map(fn c ->
            Coordinate.to_list(c)
          end)
        end),
      state.top_player_id => "#{state.top_player_id} hey top player this is your message",
      state.bot_player_id => "#{state.bot_player_id} hey bot player this is your message"
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end
end
