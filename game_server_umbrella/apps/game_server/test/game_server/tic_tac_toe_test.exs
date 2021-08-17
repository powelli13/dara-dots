defmodule GameServer.TicTacToeTest do
  use ExUnit.Case, async: true

  alias GameServer.TicTacToe
  alias Phoenix.PubSub

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
    TicTacToe.set_circle_player(state.game_pid, "1234", test_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.circle_player_name
  end

  test "should set cross player name", state do
    test_name = "cross_player"
    TicTacToe.set_cross_player(state.game_pid, "123", test_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.cross_player_name
  end

  test "should not update circle player name once set", state do
    test_name = "circle_player"
    fake_name = "blah"
    TicTacToe.set_circle_player(state.game_pid, "123", test_name)
    TicTacToe.set_circle_player(state.game_pid, "123", fake_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.circle_player_name
    refute fake_name == names.circle_player_name
  end

  test "should not update cross player name once set", state do
    test_name = "cross_player"
    fake_name = "blah"
    TicTacToe.set_cross_player(state.game_pid, "123", test_name)
    TicTacToe.set_cross_player(state.game_pid, "123", fake_name)

    names = TicTacToe.get_player_names(state.game_pid)

    assert test_name == names.cross_player_name
    refute fake_name == names.cross_player_name
  end

  test "should perform move when cross player moves first", state do
    {cross_player_id, cross_player} = {"1234", "cross"}
    set_player_names(state.game_pid, cross_player_id, cross_player, "6789", "circle_player")
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, cross_player_id, move_index)

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
    {cross_player_id, cross_player} = {"1234", "cross"}
    set_player_names(state.game_pid, cross_player_id, cross_player, "6789", "circle_player")
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, cross_player_id, move_index)

    board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(board_state, fn {i, sq} ->
      if i == move_index do
        assert sq == "X"
      else
        assert sq == " "
      end
    end)

    TicTacToe.make_move(state.game_pid, cross_player_id, move_index)

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
    {circle_player_id, circle_player} = {"1234", "circle"}
    set_player_names(state.game_pid, "6789", "cross_player", circle_player_id, circle_player)
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

    TicTacToe.make_move(state.game_pid, circle_player_id, move_index)

    board_state = TicTacToe.get_board_state(state.game_pid)

    Enum.each(board_state, fn {_, sq} ->
      assert sq == " "
    end)
  end

  test "valid move should change turn", state do
    set_player_names(state.game_pid, "1234", "cross", "6789", "circle")
    move_index = Enum.random([0, 1, 2, 3, 4, 5, 6, 7, 8])

    TicTacToe.make_move(state.game_pid, "1234", move_index)

    current_turn = TicTacToe.get_current_turn(state.game_pid)

    assert current_turn == "O"
  end

  # TODO abstract these victory detection tests
  # into a more compact/reusable state of more are added
  test "left vertical column victory registers", state do
    PubSub.subscribe(GameServer.PubSub, "ttt_game:" <> state.game_id)

    {cross_id, cross_player} = {"1234", "viclog_cross"}
    {circle_id, circle_player} = {"6789", "viclog_circle"}
    set_player_names(state.game_pid, cross_id, cross_player, circle_id, circle_player)

    TicTacToe.make_move(state.game_pid, cross_id, 0)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 1)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 3)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 2)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 6)
    assert_receive {:new_board_state, _}

    assert_receive {:game_winner, winner_piece, winner_name, winning_indices}

    assert winner_piece == "X"
    assert winner_name == cross_player
    assert winning_indices == [0, 6]
  end

  test "right vertical column victory registers", state do
    PubSub.subscribe(GameServer.PubSub, "ttt_game:" <> state.game_id)

    {cross_id, cross_player} = {"1234", "viclog_cross"}
    {circle_id, circle_player} = {"6789", "viclog_circle"}
    set_player_names(state.game_pid, cross_id, cross_player, circle_id, circle_player)

    TicTacToe.make_move(state.game_pid, cross_id, 2)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 1)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 5)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 0)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 8)
    assert_receive {:new_board_state, _}

    assert_receive {:game_winner, winner_piece, winner_name, winning_indices}

    assert winner_piece == "X"
    assert winner_name == cross_player
    assert winning_indices == [2, 8]
  end

  test "top left to bottom right diagonal victory registers", state do
    PubSub.subscribe(GameServer.PubSub, "ttt_game:" <> state.game_id)

    {cross_id, cross_player} = {"1234", "viclog_cross"}
    {circle_id, circle_player} = {"6789", "viclog_circle"}
    set_player_names(state.game_pid, cross_id, cross_player, circle_id, circle_player)

    TicTacToe.make_move(state.game_pid, cross_id, 0)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 1)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 4)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "O"

    TicTacToe.make_move(state.game_pid, circle_id, 5)
    assert_receive {:new_board_state, _}
    turn = TicTacToe.get_current_turn(state.game_pid)
    assert turn == "X"

    TicTacToe.make_move(state.game_pid, cross_id, 8)
    assert_receive {:new_board_state, _}

    assert_receive {:game_winner, winner_piece, winner_name, winning_indices}

    assert winner_piece == "X"
    assert winner_name == cross_player
    assert winning_indices == [0, 8]
  end

  test "drawn game sends out message", state do
    PubSub.subscribe(GameServer.PubSub, "ttt_game:" <> state.game_id)

    {cross_id, cross_player} = {"1234", "cross"}
    {circle_id, circle_player} = {"6789", "circle"}
    set_player_names(state.game_pid, cross_id, cross_player, circle_id, circle_player)

    TicTacToe.make_move(state.game_pid, cross_id, 0)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, circle_id, 3)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, cross_id, 1)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, circle_id, 2)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, cross_id, 4)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, circle_id, 8)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, cross_id, 7)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, circle_id, 5)
    assert_receive {:new_board_state, _}

    TicTacToe.make_move(state.game_pid, cross_id, 6)
    assert_receive {:new_board_state, _}

    assert_receive :game_drawn
  end

  defp set_player_names(
         game_pid,
         cross_player_id,
         cross_player,
         circle_player_id,
         circle_player
       ) do
    TicTacToe.set_cross_player(game_pid, cross_player_id, cross_player)
    TicTacToe.set_circle_player(game_pid, circle_player_id, circle_player)
  end
end
