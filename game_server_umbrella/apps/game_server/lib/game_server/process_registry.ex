defmodule GameServer.ProcessRegistry do
  @moduledoc """
  Simple Registry wrapper used to be able to
  name processes using strings for a variety
  of modules.
  """
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  @doc """
  Entry point that clients should use.
  key should be of the form {module, name}
  """
  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []})
  end
end