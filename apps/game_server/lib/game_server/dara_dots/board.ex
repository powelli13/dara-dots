defmodule GameServer.DaraDots.Board do
  alias __MODULE__
  alias GameServer.DaraDots.{Coordinate, LinkerPiece, RunnerPiece}

  defstruct [
    :top_linker_alpha,
    :top_linker_beta,
    :bot_linker_alpha,
    :bot_linker_beta,
    top_player_score: 0,
    bot_player_score: 0,

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
    #{:ok, test_runner_coord} = Coordinate.new(4, 2)
    #{:ok, test_runner} = RunnerPiece.new(test_runner_coord, :up)

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

  # Determine movable nodes for a square
  def get_movable_coords(%Board{} = board, piece_key) when is_atom(piece_key) do
    # Get possible nodes for the chosen piece
    curr_possibles = get_possible_move_coords(board, piece_key)

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

  defp get_possible_move_coords(%Board{} = _board, :none) do
    MapSet.new()
  end

  defp get_possible_move_coords(%Board{} = board, piece_key) when is_atom(piece_key) do
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

  defp get_linker_piece_keys(),
    do: MapSet.new([:top_linker_alpha, :top_linker_beta, :bot_linker_alpha, :bot_linker_beta])

  # Move a linker and update its link
  def move_linker_and_link(%Board{} = board, linker_key, %Coordinate{} = dest_coord) do
    movable_coords = get_movable_coords(board, linker_key)

    if MapSet.member?(movable_coords, dest_coord) do
      with {:ok, linker} <- Map.fetch(board, linker_key) do
        moved_linker =
          LinkerPiece.move(linker, dest_coord)
          |> LinkerPiece.set_link(linker.coord, dest_coord)

        Map.put(board, linker_key, moved_linker)
      end
    else
      board
    end
  end

  def move_linker_and_link(%Board{} = board, :none, %Coordinate{} = _coord) do
    board
  end

  def move_linker_no_link(%Board{} = board, linker_key, %Coordinate{} = dest_coord) do
    movable_coords = get_movable_coords(board, linker_key)

    if MapSet.member?(movable_coords, dest_coord) do
      with {:ok, linker} <- Map.fetch(board, linker_key) do
        moved_linker = LinkerPiece.move(linker, dest_coord)
        Map.put(board, linker_key, moved_linker)
      end
    else
      board
    end
  end

  def move_linker_no_link(%Board{} = board, :none, %Coordinate{} = _coord) do
    board
  end

  # Allow for placement of Runners
  def place_runner(%Board{} = board, %Coordinate{row: 1} = coord) do
    place_runner(board, coord, :up)
  end

  def place_runner(%Board{} = board, %Coordinate{row: 5} = coord) do
    place_runner(board, coord, :down)
  end

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

  def advance_runners(%Board{} = board) do
    all_link_coords = get_all_link_coords(board)

    # check for victory
    # TODO find a way to gracefully advance runners in turn and check for scoring
    # reduce_while should help with that
    # if we want to advance by age we need to sort by runner_timer ascending
    {runners_and_keys, new_board} =
      board.runner_pieces
      |> Enum.map_reduce(board, fn {entry_time, runner}, acc_board ->
        {advanced_runner, new_board} =
          handle_advanced_runner(acc_board, runner, all_link_coords)

        # TODO this could be simplified if I do not use a map to store runners
        # still undecided on giving priority to older runners though
        # so I'll leave the structure for now
        # Preserve the entry time key
        {{entry_time, advanced_runner}, new_board}
      end)

    #IO.inspect "!!!!!!!!!!!!!!!!!!! Runners and keys"
    #IO.inspect runners_and_keys
    
    advanced_runners = remove_scored_runners(runners_and_keys)

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
    |> Map.new
  end

  defp get_all_link_coords(%Board{} = board) do
    get_linker_piece_keys()
    |> Enum.map(fn key ->
      {:ok, piece} = Map.fetch(board, key)
      piece.link_coords
    end)
    |> Enum.filter(fn coord ->
      coord != nil
    end)
  end
end
