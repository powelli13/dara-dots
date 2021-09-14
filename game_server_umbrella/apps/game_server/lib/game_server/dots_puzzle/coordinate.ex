defmodule GameServer.Coordinate do
  @moduledoc """
  Data structure that maintains a single position
  on the board. A coordinate represents the position
  of either a board dot or a playing piece.
  """
  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct row: 0,
            col: 0

  def new(row, col) do
    {:ok, %Coordinate{row: row, col: col}}
  end
end
