defmodule GameServer.PongPlayerQueueTest do
  use ExUnit.Case, async: true

  alias GameServer.PongPlayerQueue
  # alias Phoenix.PubSub

  test "add one player should have size of one" do
    PongPlayerQueue.add_player("123", "name")

    queue_size = PongPlayerQueue.get_queue_size()

    assert queue_size == 1
  end

  test "adding two players should have size of zero" do
    PongPlayerQueue.add_player("123", "name")
    PongPlayerQueue.add_player("456", "opponent")

    queue_size = PongPlayerQueue.get_queue_size()

    assert queue_size == 0
  end
end
