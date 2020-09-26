defmodule GameServerWeb.LipSyncLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  alias GameServerWeb.LipSyncView
  alias GameServerWeb.Presence

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(GameServer.PubSub, "lipsync:test")
    end

    {:ok,
     socket
     |> assign(:draft_message, "")
     |> assign(:messages, [])}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    LipSyncView.render("lip_sync.html", assigns)
  end

  @impl Phoenix.LiveView
  def handle_event("send_message", %{"message" => message}, socket) do
    PubSub.broadcast(GameServer.PubSub, "lipsync:test", {:new_message, message})

    {:noreply,
     socket
     |> assign(:draft_message, "")}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, message}, socket) do
    # TODO figure out best way to append message here
    # consider using update
    # or create a gen server to hold messages?
    messages = socket.assigns.messages
    {:noreply, assign(socket, :messages, [message | messages])}
  end
end
