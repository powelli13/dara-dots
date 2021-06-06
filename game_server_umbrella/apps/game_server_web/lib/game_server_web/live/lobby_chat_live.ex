defmodule GameServerWeb.LobbyChatLive do
  use Phoenix.LiveView
  # alias Phoenix.PubSub
  # alias GameServerWeb.LipSyncView
  # alias GameServerWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # PubSub.subscribe(GameServer.PubSub, "lobby_chat:test")
      Process.send_after(self(), :second_tick, 1000)
    end

    {:ok, socket |> assign(:count, 0)}
  end

  def handle_info(:second_tick, socket) do
    Process.send_after(self(), :second_tick, 1000)
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  def render(assigns) do
    ~L"""
    Hello hi there!
    Been here for <%= @count %> seconds.
    """
  end
end
