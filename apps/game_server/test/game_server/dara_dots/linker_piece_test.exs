defmodule GameServer.DaraDots.LinkerPieceTest do
  use ExUnit.Case, async: true

  alias GameServer.DaraDots.{Coordinate, LinkerPiece}

  setup do
    {:ok, coord} = Coordinate.new(1, 1)
    {:ok, linker} = LinkerPiece.new(coord)

    {:ok, linker: linker}
  end

  test "adding link next to coord should add link", state do
    {:ok, start_coord} = Coordinate.new(1, 1)
    {:ok, finish_coord} = Coordinate.new(1, 2)

    with_link = LinkerPiece.set_link(state[:linker], start_coord, finish_coord)

    assert with_link.link_coords != nil
    assert MapSet.member?(with_link.link_coords, start_coord)
    assert MapSet.member?(with_link.link_coords, finish_coord)
  end

  test "illegal link coords should not add link", state do
    {:ok, bad_start} = Coordinate.new(1, 5)
    {:ok, bad_finish} = Coordinate.new(5, 1)

    try_link = LinkerPiece.set_link(state[:linker], bad_start, bad_finish)

    assert try_link.link_coords == nil
  end

  test "new linker should have nil link_coords" do
    {:ok, start_coord} = Coordinate.new(1, 1)

    {:ok, linker} = LinkerPiece.new(start_coord)

    assert linker.link_coords == nil
  end

  test "move should update coordinate" do
    {:ok, start_coord} = Coordinate.new(1, 1)

    {dest_row, dest_col} = {1, 2}
    {:ok, dest_coord} = Coordinate.new(dest_row, dest_col)

    {:ok, linker} = LinkerPiece.new(start_coord)

    moved_linker = LinkerPiece.move(linker, dest_coord)

    assert moved_linker.coord.row == dest_row
    assert moved_linker.coord.col == dest_col
  end

  test "move_and_set_link should update coordinate" do
    with {:ok, start_coord} = Coordinate.new(3, 3),
         {dest_row, dest_col} = {3, 4},
         {:ok, dest_coord} = Coordinate.new(dest_row, dest_col),
         {:ok, linker} = LinkerPiece.new(start_coord) do
      moved_linker = LinkerPiece.move_and_set_link(linker, dest_coord)

      assert moved_linker.coord.row == dest_row
      assert moved_linker.coord.col == dest_col
    end
  end

  test "move_and_set_link should update link" do
    with {:ok, start_coord} = Coordinate.new(3, 3),
         {dest_row, dest_col} = {3, 4},
         {:ok, dest_coord} = Coordinate.new(dest_row, dest_col),
         {:ok, linker} = LinkerPiece.new(start_coord) do
      moved_linker = LinkerPiece.move_and_set_link(linker, dest_coord)

      assert moved_linker.link_coords != nil
      assert MapSet.member?(moved_linker.link_coords, start_coord)
      assert MapSet.member?(moved_linker.link_coords, dest_coord)
    end
  end
end
