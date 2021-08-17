defmodule GameServer.PongPlayerQueueTest do
  use ExUnit.Case, async: true

  alias GameServer.PongPlayerQueue
  alias Phoenix.PubSub

  test "add one player should have size of one", state do
    PongPlayerQueue.add_player("123", "name")

    queue_size = PongPlayerQueue.get_queue_size()

    assert queue_size == 1
  end
end