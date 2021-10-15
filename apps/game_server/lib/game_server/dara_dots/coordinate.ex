defmodule GameServer.DaraDots.Coordinate do
  @moduledoc """
  Data structure that maintains a single position
  on the board. A coordinate represents the position
  of either a board dot or a playing piece.
  """
  alias __MODULE__

  @row_range 0..4
  @col_range 0..4

  @enforce_keys [:row, :col]
  defstruct row: 0,
            col: 0

  def new(row, col) when row in (@row_range) and col in (@col_range) do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col) do
    {:error, :invalid_coordinate}
  end
end
