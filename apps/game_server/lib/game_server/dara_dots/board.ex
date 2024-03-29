defmodule GameServer.DaraDots.Board do
  alias __MODULE__
  alias GameServer.DaraDots.{Coordinate, LinkerPiece, RunnerPiece}
  @actions_per_turn_count 3

  # TODO split the data struct and the board operations and rules
  # game should operate on the board controlling rules
  # should the board know about player IDs though?
  defstruct [
    :top_linker_alpha,
    :top_linker_beta,
    :bot_linker_alpha,
    :bot_linker_beta,
    top_player_score: 0,
    bot_player_score: 0,
    # TODO Board module should be responsible for changing turn to keep state consistent
    current_turn: :top_player,
    current_turn_action_count: @actions_per_turn_count,

    # Used to save the age of the triangles as they are added to the board
    # TODO consider restructuring the data structures used for runner pieces
    runner_timer: 2,
    runner_pieces: Map.new(),
    dot_coords: MapSet.new()
  ]

  def new() do
    # These are only for initial visual testing
    new_board = create_empty_board()

    {
      :ok,
      place_initial_runners(new_board)
    }
  end

  # Method to create the initial board with no runners for testing purposes
  def new_test() do
    {
      :ok,
      create_empty_board()
    }
  end

  defp create_empty_board() do
    with {:ok, bot_alpha_coord} <- Coordinate.new(1, 2),
         {:ok, bot_beta_coord} <- Coordinate.new(1, 4),
         {:ok, top_alpha_coord} <- Coordinate.new(5, 2),
         {:ok, top_beta_coord} <- Coordinate.new(5, 4),
         {:ok, bot_alpha} <- LinkerPiece.new(bot_alpha_coord),
         {:ok, bot_beta} <- LinkerPiece.new(bot_beta_coord),
         {:ok, top_alpha} <- LinkerPiece.new(top_alpha_coord),
         {:ok, top_beta} <- LinkerPiece.new(top_beta_coord) do
      %Board{
        bot_linker_alpha: bot_alpha,
        bot_linker_beta: bot_beta,
        top_linker_alpha: top_alpha,
        top_linker_beta: top_beta,
        dot_coords: MapSet.new(build_grid_coords())
      }
    end
  end

  defp place_initial_runners(%Board{} = board) do
    with {:ok, bot_runner_coord} <- Coordinate.new(1, 1),
         {:ok, top_runner_coord} <- Coordinate.new(5, 5),
         {:ok, top_runner} <- RunnerPiece.new(top_runner_coord, :down),
         {:ok, bot_runner} <- RunnerPiece.new(bot_runner_coord, :up) do
      %Board{
        board
        | runner_pieces: %{0 => top_runner, 1 => bot_runner}
      }
    end
  end

  defp build_grid_coords() do
    Enum.map(1..5, fn n -> Enum.map(1..5, fn i -> {n, i} end) end)
    |> List.flatten()
    |> Enum.map(fn {row, col} ->
      {:ok, coord} = Coordinate.new(row, col)
      coord
    end)
  end

  def is_player_turn?(%Board{} = board, player) do
    board.current_turn == player
  end

  def is_top_turn?(%Board{} = board) do
    board.current_turn == :top_player
  end

  def is_bot_turn?(%Board{} = board) do
    board.current_turn == :bot_player
  end

  def is_players_piece?(player, piece_key) do
    case player do
      :top_player ->
        piece_key == :top_linker_alpha ||
          piece_key == :top_linker_beta

      :bot_player ->
        piece_key == :bot_linker_alpha ||
          piece_key == :bot_linker_beta
    end
  end

  def get_current_turn(%Board{} = board) do
    board.current_turn
  end

  # TODO eventually these will need to be updated to allow for move confirmation
  # and undoing pending actions
  def decrement_action_count_check_turn(%Board{} = board) do
    new_actions_count = board.current_turn_action_count - 1

    cond do
      # When the count equals zero then we allow changing turn
      # and disallow any more actions
      new_actions_count >= 0 ->
        %Board{board | current_turn_action_count: new_actions_count}

      true ->
        board
    end
  end

  def change_turn(%Board{} = board) do
    cond do
      board.current_turn_action_count == 0 ->
        change_turn_internal(board)

      true ->
        board
    end
  end

  defp change_turn_internal(%Board{current_turn: :top_player} = board) do
    %Board{board | current_turn: :bot_player, current_turn_action_count: @actions_per_turn_count}
  end

  defp change_turn_internal(%Board{current_turn: :bot_player} = board) do
    %Board{board | current_turn: :top_player, current_turn_action_count: @actions_per_turn_count}
  end

  # Determines if it is the players turn and if the move is legal
  # This checks moving linker without link, will most likely need more
  def is_legal_move_coord?(%Board{} = board, player, piece_key, dest_coord) do
    movable_coords = get_movable_coords(board, piece_key)

    MapSet.member?(movable_coords, dest_coord) && is_player_turn?(board, player)
  end

  # Determine movable nodes for a square
  def get_movable_coords(%Board{} = board, piece_key) when is_atom(piece_key) do
    # Get possible nodes for the chosen piece
    curr_possibles = get_possible_move_coords(board, piece_key, :movable)

    other_keys = MapSet.difference(get_linker_piece_keys(), MapSet.new([piece_key]))

    # Get the possible nodes for other linker pieces
    other_linker_coords =
      Enum.map(other_keys, fn key ->
        {:ok, other_piece} = Map.fetch(board, key)
        other_piece.coord
      end)
      |> MapSet.new()

    MapSet.difference(curr_possibles, other_linker_coords)
  end

  defp get_possible_move_coords(%Board{} = _board, :none, _type) do
    MapSet.new()
  end

  defp get_possible_move_coords(%Board{} = board, piece_key, :movable)
       when is_atom(piece_key) do
    {:ok, piece} = Map.fetch(board, piece_key)

    curr = piece.coord

    # Orthogonal rows
    rows_set =
      Enum.reduce([-1, 1], MapSet.new(), fn d, ms ->
        case Coordinate.new(curr.row + d, curr.col) do
          {:ok, new_coord} ->
            MapSet.put(ms, new_coord)

          {:error, _error} ->
            ms
        end
      end)

    # Orthogonal columns
    cols_set =
      Enum.reduce([-1, 1], MapSet.new(), fn d, ms ->
        case Coordinate.new(curr.row, curr.col + d) do
          {:ok, new_coord} ->
            MapSet.put(ms, new_coord)

          {:error, _error} ->
            ms
        end
      end)

    # Return movable nodes
    MapSet.union(rows_set, cols_set)
  end

  defp get_possible_move_coords(%Board{} = board, piece_key, :linkable) when is_atom(piece_key) do
    {:ok, piece} = Map.fetch(board, piece_key)

    curr = piece.coord

    # Orthogonal columns
    cols_set =
      Enum.reduce([-1, 1], MapSet.new(), fn d, ms ->
        case Coordinate.new(curr.row, curr.col + d) do
          {:ok, new_coord} ->
            MapSet.put(ms, new_coord)

          {:error, _error} ->
            ms
        end
      end)

    cols_set
  end

  def get_linkable_coords(%Board{} = board, piece_key) when is_atom(piece_key) do
    # Get possible nodes for the chosen piece
    curr_possibles = get_possible_move_coords(board, piece_key, :linkable)

    other_keys = MapSet.difference(get_linker_piece_keys(), MapSet.new([piece_key]))

    # Get the possible nodes for other linker pieces
    other_linker_coords =
      Enum.map(other_keys, fn key ->
        {:ok, other_piece} = Map.fetch(board, key)
        other_piece.coord
      end)
      |> MapSet.new()

    MapSet.difference(curr_possibles, other_linker_coords)
  end

  defp get_linker_piece_keys(),
    do: MapSet.new([:top_linker_alpha, :top_linker_beta, :bot_linker_alpha, :bot_linker_beta])

  # Move a linker and update its link
  def move_linker_and_link(
        %Board{} = board,
        player,
        linker_key,
        %Coordinate{} = dest_coord
      ) do
    if is_legal_move_coord?(board, player, linker_key, dest_coord) do
      with {:ok, linker} <- Map.fetch(board, linker_key) do
        moved_linker = LinkerPiece.move_and_set_link(linker, dest_coord)

        Map.put(board, linker_key, moved_linker)
        |> decrement_action_count_check_turn
      end
    else
      board
    end
  end

  def move_linker_and_link(%Board{} = board, _player, :none, %Coordinate{} = _coord) do
    board
  end

  def move_linker_no_link(
        %Board{} = board,
        player,
        linker_key,
        %Coordinate{} = dest_coord
      ) do
    if is_legal_move_coord?(board, player, linker_key, dest_coord) do
      with {:ok, linker} <- Map.fetch(board, linker_key) do
        moved_linker = LinkerPiece.move(linker, dest_coord)

        Map.put(board, linker_key, moved_linker)
        |> decrement_action_count_check_turn
      end
    else
      board
    end
  end

  def move_linker_no_link(%Board{} = board, :none, %Coordinate{} = _coord) do
    board
  end

  # Allow for placement of Runners
  def place_runner_for_player(%Board{} = board, player, %Coordinate{row: 1} = coord) do
    # TODO need is legal move checks for these
    # should check player turn
    # player should only place in their home row
    # TODO need placement markers on both home rows
    # node should be open
    if is_legal_runner_placement?(board, player, coord) do
      place_runner(board, coord, :up)
    else
      # TODO need some kind of state management for illegal moves
      board
    end
  end

  def place_runner_for_player(%Board{} = board, player, %Coordinate{row: 5} = coord) do
    if is_legal_runner_placement?(board, player, coord) do
      place_runner(board, coord, :down)
    else
      board
    end
  end

  # If an invalid row is given then do nothing
  def place_runner(%Board{} = board, _coord) do
    IO.puts "doing nothing"
    board
  end

  def clear_runner_animate_paths(%Board{} = board) do
    # TODO unit tests for this
    reset_runners =
      board.runner_pieces
      |> Enum.map(fn {k, runner} ->
        reset_runner = RunnerPiece.reset_path_to_animate(runner)
        {k, reset_runner}
      end)
      |> Map.new()

    %Board{board | runner_pieces: reset_runners}
  end

  def node_has_runner?(%Board{} = board, %Coordinate{} = coord) do
    board.runner_pieces
    |> Enum.any?(fn {_k, runner} ->
      Coordinate.equal?(runner.coord, coord)
    end)
  end

  def node_has_linker?(%Board{} = board, %Coordinate{} = coord) do
    [
      board.top_linker_alpha.coord,
      board.top_linker_beta.coord,
      board.bot_linker_alpha.coord,
      board.bot_linker_beta.coord
    ]
    |> Enum.any?(fn linker_coord ->
      Coordinate.equal?(linker_coord, coord)
    end)
  end

  def is_legal_runner_placement?(%Board{} = board, :top_player, %Coordinate{} = coord) do
    if !node_has_runner?(board, coord) &&
         coord.row == 5 do
      true
    else
      false
    end
  end

  def is_legal_runner_placement?(%Board{} = board, :bot_player, %Coordinate{} = coord) do
    if !node_has_runner?(board, coord) &&
         coord.row == 1 do
      true
    else
      false
    end
  end

  # TODO this breaks things because the player param was added above
  defp place_runner(%Board{} = board, %Coordinate{} = coord, facing) do
    with {:ok, new_runner} <- RunnerPiece.new(coord, facing) do
      %Board{
        board
        | runner_pieces:
            Map.put(
              board.runner_pieces,
              board.runner_timer,
              new_runner
            ),
          runner_timer: board.runner_timer + 1
      }
    end
  end

  def score_goal(%Board{} = board, :top_goal) do
    %Board{board | bot_player_score: board.bot_player_score + 1}
  end

  def score_goal(%Board{} = board, :bot_goal) do
    %Board{board | top_player_score: board.top_player_score + 1}
  end

  def get_all_link_coords(%Board{} = board) do
    get_linker_piece_keys()
    |> Enum.map(fn key ->
      {:ok, piece} = Map.fetch(board, key)
      piece.link_coords
    end)
    |> Enum.filter(fn coord ->
      coord != nil
    end)
  end

  def advance_runners(%Board{} = board) do
    all_link_coords = get_all_link_coords(board)

    # check for victory
    {runners_and_keys, new_board} =
      board.runner_pieces
      |> Enum.map_reduce(board, fn {entry_time, runner}, acc_board ->
        {advanced_runner, new_board} = handle_advanced_runner(acc_board, runner, all_link_coords)

        # TODO this could be simplified if I do not use a map to store runners
        # still undecided on giving priority to older runners though
        # so I'll leave the structure for now
        # Preserve the entry time key
        {{entry_time, advanced_runner}, new_board}
      end)

    advanced_runners = remove_scored_runners(runners_and_keys)

    # TODO left off this is corrupting the data structure of the runners
    # Need to return to a Map here
    %{new_board | runner_pieces: advanced_runners}
  end

  defp handle_advanced_runner(%Board{} = board, %RunnerPiece{} = runner, all_link_coords) do
    case RunnerPiece.advance(runner, all_link_coords) do
      {:goal, goal, _new_runner} ->
        {nil, score_goal(board, goal)}

      {:no_goal, new_runner} ->
        {new_runner, board}
    end
  end

  # Scored runners are returned as nil, remove those runners
  defp remove_scored_runners(runners) do
    runners
    |> Enum.filter(fn {_key, runner} ->
      runner != nil
    end)
    |> Map.new()
  end
end
