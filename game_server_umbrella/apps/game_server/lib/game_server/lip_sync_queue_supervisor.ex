defmodule GameServer.LipSyncQueueSupervisor do
  @moduledoc """
  Dynamic supervisor used to retrieve PIDs for
  running LipSync queues.
  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    # TODO is one_for_one best here?
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Used to retrieve the process for a Lip Sync queue
  or start it if it hasn't started yet.
  """
  def find_queue(queue_id) do
    case start_child(queue_id) do
      {:ok, pid} -> pid
      # TODO may want to update this to ensure that duplicate IDs aren't started
      {:error, {:already_started, pid}} -> pid
    end
  end

  def start_child(queue_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GameServer.LipSyncQueue, queue_id}
    )
  end
end
