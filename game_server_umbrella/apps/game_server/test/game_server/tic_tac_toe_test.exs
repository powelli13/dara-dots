defmodule GameServer.TicTacToeTest do
  use ExUnit.Case, async: true

  alias GameServer.TicTacToe

  setup do
    game_id = "test_ttt_id"
    {:ok, pid} = GenServer.start_link(GameServer.TicTacToe, game_id)

    {:ok, ttt_game_pid: pid, game_id: game_id}
  end

  test "initial board is empty", state do
    init_board = TicTacToe.get_board_state(state[:ttt_game_pid])

    assert length(init_board) == 9, "incorrect board length"

    Enum.map(init_board, fn sq ->
      assert sq == " "
    end)
  end

  test "initial player names blank", state do
    %{
      :cross_player_name => cross_player,
      :circle_player_name => circle_player
    } = TicTacToe.get_player_names(state[:ttt_game_pid])

    assert circle_player == ""
    assert cross_player == ""
  end

  test "should set circle player name", state do
    test_name = "circle_player"
    TicTacToe.set_circle_player(state[:ttt_game_pid], test_name)

    names = TicTacToe.get_player_names(state.ttt_game_pid)

    assert test_name == names.circle_player_name
  end

  test "should set cross player name", state do
    test_name = "cross_player"
    TicTacToe.set_cross_player(state[:ttt_game_pid], test_name)

    names = TicTacToe.get_player_names(state.ttt_game_pid)

    assert test_name == names.cross_player_name
  end

  test "should not update circle player name once set", state do
    test_name = "circle_player"
    fake_name = "blah"
    TicTacToe.set_circle_player(state.ttt_game_pid, test_name)
    TicTacToe.set_circle_player(state.ttt_game_pid, fake_name)

    names = TicTacToe.get_player_names(state.ttt_game_pid)

    assert test_name == names.circle_player_name
    refute fake_name == names.circle_player_name
  end

  test "should not update cross player name once set", state do
    test_name = "cross_player"
    fake_name = "blah"
    TicTacToe.set_cross_player(state.ttt_game_pid, test_name)
    TicTacToe.set_cross_player(state.ttt_game_pid, fake_name)

    names = TicTacToe.get_player_names(state.ttt_game_pid)

    assert test_name == names.cross_player_name
    refute fake_name == names.cross_player_name
  end
end
