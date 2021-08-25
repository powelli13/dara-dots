defmodule GameServer.PongGameSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
  end

  # TODO combine all game supervisors into one that takes
  # a tuple of Game.Module, game_id
  # then expose multiple start_ttt_child, start_pong_child etc.
  # to allow for one supervisor to start multiple
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def find_or_create_game(game_id) do
    case start_child(game_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def start_child(game_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GameServer.PongGame, game_id}
    )
  end
end
