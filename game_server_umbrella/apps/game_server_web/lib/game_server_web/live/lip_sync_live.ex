defmodule GameServerWeb.LipSyncLive do
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div>Welcome to Lip Sync battle!</div>
    """
  end
end