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
         {:ok, bot_beta_coord} <- Coordinate.new(1, 4),
         {:ok, top_alpha_coord} <- Coordinate.new(5, 2),
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
  # def get_movable_coords(%Board{} = board, %) do
  # end

  # Move a square and update its link

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
