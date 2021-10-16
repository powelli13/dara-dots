defmodule GameServer.DaraDots.Board do
  alias __MODULE__
  alias GameServer.DaraDots.{Coordinate, LinkerPiece, RunnerPiece}

  defstruct [
    :top_linker_alpha,
    :top_linker_beta,
    :bot_linker_alpha,
    :bot_linker_beta,

    # Used to save the age of the triangles as they are added to the board
    runner_timer: 0,
    runner_pieces: Map.new(),
    dot_coords: MapSet.new()
  ]

  def new() do
    with {:ok, bot_alpha_coord} <- Coordinate.new(1, 2),
         {:ok, bot_beta_coord} <- Coordinate.new(1, 3),
         {:ok, top_alpha_coord} <- Coordinate.new(5, 3),
         {:ok, top_beta_coord} <- Coordinate.new(5, 4),
         {:ok, bot_alpha} <- LinkerPiece.new(bot_alpha_coord),
         {:ok, bot_beta} <- LinkerPiece.new(bot_beta_coord),
         {:ok, top_alpha} <- LinkerPiece.new(top_alpha_coord),
         {:ok, top_beta} <- LinkerPiece.new(top_beta_coord) do
      {:ok,
       %Board{
         bot_linker_alpha: bot_alpha,
         bot_linker_beta: bot_beta,
         top_linker_alpha: top_alpha,
         top_linker_beta: top_beta,
         dot_coords: MapSet.new(build_grid_coords())
       }}
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

  # Move a square and update its link
  # def move_linker(%Board{} = board, %LinkerPiece{} = linker, %Coordinate{} = dest_coord) do
  # board
  # end

  # Advance all Runners, check for and take links, resolve collisions
  # check for scoring when moving
  # check for victory

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
end
