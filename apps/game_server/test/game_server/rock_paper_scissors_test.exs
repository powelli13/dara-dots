defmodule GameServer.RockPaperScissorsTest do
  use ExUnit.Case, async: true

  alias GameServer.RockPaperScissors
  alias Phoenix.PubSub

  setup do
    game_id = "test_rps_id"
    {:ok, pid} = GenServer.start_link(GameServer.RockPaperScissors, game_id)

    {:ok, game_pid: pid, game_id: game_id}
  end

  test "add one player", state do
    test_name = "Rumplestiltskin"

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name, "123")
    player_names = RockPaperScissors.get_player_names_by_pid(state[:game_pid])

    assert player_names[:player_one_name] == test_name
  end

  test "add two players", state do
    test_name_one = "Rumplestiltskin"
    test_name_two = "Pied Piper"

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_one, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_two, "456")

    player_names = RockPaperScissors.get_player_names_by_pid(state[:game_pid])

    assert player_names[:player_one_name] == test_name_one
    assert player_names[:player_two_name] == test_name_two
  end

  test "adding another player does not remove existing players", state do
    test_name_one = "Rumplestiltskin"
    test_name_two = "Pied Piper"

    test_name_excess = "Do Not Add"

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_one, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_two, "456")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_excess, "798")

    player_names = RockPaperScissors.get_player_names_by_pid(state[:game_pid])

    assert player_names[:player_one_name] == test_name_one
    assert player_names[:player_two_name] == test_name_two
  end

  test "player names persist after a move is made", state do
    test_name_one = "Rumplestiltskin"
    test_name_two = "Pied Piper"

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_one, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_two, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name_one, :rock)

    player_names = RockPaperScissors.get_player_names_by_pid(state[:game_pid])

    assert player_names[:player_one_name] == test_name_one
    assert player_names[:player_two_name] == test_name_two
  end

  test "player one makes move", state do
    test_name = "PlayerOne"
    test_move = :rock

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name, "123")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name, test_move)

    player_moves = RockPaperScissors.get_player_moves_by_pid(state[:game_pid])

    assert player_moves[:player_one_move] == test_move
    assert player_moves[:player_two_move] == nil
  end

  test "both players make moves", state do
    # Subscribe to receive endgame state after moves are submitted
    # RPS server stops after both moves are submitted,
    # so we subscribe to receive endgame state
    PubSub.subscribe(GameServer.PubSub, "rps_game:" <> state[:game_id])

    test_name_one = "PlayerOne"
    test_name_two = "PlayerTwo"

    test_move_one = :rock
    test_move_two = :paper

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_one, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_two, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name_one, test_move_one)
    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name_two, test_move_two)

    assert_receive {:game_winner, winner_name}

    assert winner_name == test_name_two
  end

  test "both players move game drawn", state do
    PubSub.subscribe(GameServer.PubSub, "rps_game:" <> state[:game_id])

    test_name_one = "PlayerOne"
    test_name_two = "PlayerTwo"

    test_move_one = :rock
    test_move_two = :rock

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_one, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_name_two, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name_one, test_move_one)
    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_name_two, test_move_two)

    assert_receive :game_drawn
  end

  test "paper beats rock", state do
    PubSub.subscribe(GameServer.PubSub, "rps_game:" <> state[:game_id])

    test_winner = "PaperPlayer"
    test_loser = "RockPlayer"

    winner_move = :paper
    loser_move = :rock

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_winner, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_loser, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_winner, winner_move)
    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_loser, loser_move)

    assert_receive {:game_winner, winner_name}

    assert winner_name == test_winner
  end

  test "rock beats scissors", state do
    PubSub.subscribe(GameServer.PubSub, "rps_game:" <> state[:game_id])

    test_winner = "RockPlayer"
    test_loser = "ScissorsPlayer"

    winner_move = :rock
    loser_move = :scissors

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_winner, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_loser, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_winner, winner_move)
    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_loser, loser_move)

    assert_receive {:game_winner, winner_name}

    assert winner_name == test_winner
  end

  test "scissors beats paper", state do
    PubSub.subscribe(GameServer.PubSub, "rps_game:" <> state[:game_id])

    test_winner = "ScissorsPlayer"
    test_loser = "PaperPlayer"

    winner_move = :scissors
    loser_move = :paper

    RockPaperScissors.add_player_by_pid(state[:game_pid], test_winner, "123")
    RockPaperScissors.add_player_by_pid(state[:game_pid], test_loser, "456")

    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_winner, winner_move)
    RockPaperScissors.enter_move_by_pid(state[:game_pid], test_loser, loser_move)

    assert_receive {:game_winner, winner_name}

    assert winner_name == test_winner
  end
end
