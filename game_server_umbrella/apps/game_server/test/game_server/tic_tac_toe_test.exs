defmodule GameServer.TicTacToeTest do
  use ExUnit.Case, async: true

  alias GameServer.TicTacToe

  setup do
    game_id = "test_ttt_id"
    {:ok, pid} = GenServer.start_link(GameServer.TicTacToe, game_id)

    {:ok, game_pid: pid, game_id: game_id}
  end

  test "initial board is empty", state do
    init_board = TicTacToe.get_board_state(state.game_pid)

    assert length(Map.to_list(init_board)) == 9, "incorrect board length"

    Enum.each(init_board, fn {_, sq} ->
      assert sq == " "
    end)
  end

  test "initial player names blank", state do
    %{
      :cross_player_name => cross_player,
      :circle_player_name => circle_player
    } = TicTacToe.get_player_names(state.game_pid)

    assert circle_player == ""
    assert cross_player == ""
  end

  test "should set circle player name", state do
    test_name = "circle_player"
    TicTacToe.set_circle_player(state.game_pid, test_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.circle_player_name
  end

  test "should set cross player name", state do
    test_name = "cross_player"
    TicTacToe.set_cross_player(state.game_pid, test_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.cross_player_name
  end

  test "should not update circle player name once set", state do
    test_name = "circle_player"
    fake_name = "blah"
    TicTacToe.set_circle_player(state.game_pid, test_name)
    TicTacToe.set_circle_player(state.game_pid, fake_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.circle_player_name
    refute fake_name == names.circle_player_name
  end

  test "should not update cross player name once set", state do
    test_name = "cross_player"
    fake_name = "blah"
    TicTacToe.set_cross_player(state.game_pid, test_name)
    TicTacToe.set_cross_player(state.game_pid, fake_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.cross_player_name
    refute fake_name == names.cross_player_name
  end

  test "should perform move when cross player moves first", state do
    cross_player = "cross"
    set_player_names(state.game_pid, cross_player, "circle_player")
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, cross_player, move_index)

    board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(board_state, fn {i, sq} ->
      if i == move_index do
        assert sq == "X"
      else
        assert sq == " "
      end
    end)
  end

  test "submitting moves in the same square do not change board state", state do
    cross_player = "cross"
    set_player_names(state.game_pid, cross_player, "circle_player")
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, cross_player, move_index)

    board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(board_state, fn {i, sq} ->
      if i == move_index do
        assert sq == "X"
      else
        assert sq == " "
      end
    end)

    TicTacToe.make_move(state.game_pid, cross_player, move_index)

    second_board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(second_board_state, fn {i, sq} ->
      if i == move_index do
        assert sq == "X"
      else
        assert sq == " "
      end
    end)
  end

  test "wrong player turn submitting move does not change board state", state do
    circle_player = "circle"
    set_player_names(state.game_pid, "cross_player", circle_player)
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, circle_player, move_index)

    board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(board_state, fn {_, sq} ->
      assert sq == " "
    end)
  end

  defp set_player_names(
         game_pid,
         cross_player,
         circle_player
       ) do
    TicTacToe.set_cross_player(game_pid, cross_player)
    TicTacToe.set_cross_player(game_pid, circle_player)
  end
end
