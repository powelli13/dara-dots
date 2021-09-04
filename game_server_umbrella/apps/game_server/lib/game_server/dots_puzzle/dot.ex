defmodule GameServer.Dot do
  @moduledoc """
  Data structure used to represent the state of a single dot,
  or node, on the board.
  Defaults to not being empty, and not a home or destination dot for any piece.
  """
  alias __MODULE__

  defstruct home_piece: :none,
            destination_piece: :none,
            stamp: :empty

  @doc """
  Creates a new dot that will act as the home dot for the given piece.
  """
  def new_home_dot(piece) when is_atom(piece) do
    %Dot{home_piece: piece}
  end

  @doc """
  Creates a new dot that will act as the destination dot for the given piece.
  """
  def new_destination_dot(piece) when is_atom(piece) do
    %Dot{destination_piece: piece}
  end
end
