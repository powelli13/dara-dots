defmodule GameServer.DaraDots.Coordinate do
  @moduledoc """
  Data structure that maintains a single position
  on the board. A coordinate represents the position
  of either a board dot or a playing piece.
  """
  alias __MODULE__

  @min_row 1
  @max_row 5

  @min_col 1
  @max_col 5

  @row_range @min_row..@max_row
  @col_range @min_col..@max_col

  @enforce_keys [:row, :col]
  defstruct row: 0,
            col: 0

  def new(row, col) when row in @row_range and col in @col_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col) do
    {:error, :invalid_coordinate}
  end

  def equal?(%Coordinate{} = coord, %Coordinate{} = other) do
    coord.row == other.row && coord.col == other.col
  end

  # Used to transform the Coordinate into a list to be broadcast by the channels
  def to_list(%Coordinate{} = coord) do
    [coord.row, coord.col]
  end

  # Min and max rows are used to determine when a runner piece scores
  def get_min_row(), do: @min_row

  def get_max_row(), do: @max_row

  def get_min_col(), do: @min_col

  def get_max_col(), do: @max_col
end
