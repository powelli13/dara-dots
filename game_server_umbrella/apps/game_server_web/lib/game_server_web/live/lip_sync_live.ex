defmodule GameServerWeb.LipSyncLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    connected = connected?(socket)

    if connected do
      PubSub.subscribe(GameServer.PubSub, "lipsync:test")
    end

    {:ok,
     socket
     |> assign(:connected, connected)
     |> assign(:messages, [])}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div>Welcome to Lip Sync battle!</div>
    <div>We are <%= @connected %> connected!</div>
    <div>Messages</div>
    <%= for message <- @messages do %>
    <div><%= message %></div>
    <% end %>
    <textarea rows="2" placeholder="Chat">
    </textarea>
    <button phx-click="send_message">
      Send
    </buton>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("send_message", _value, socket) do
    PubSub.broadcast(GameServer.PubSub, "lipsync:test", {:new_message, "hi there!"})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, message}, socket) do
    #TODO figure out best way to append message here
    # consider using update
    # or create a gen server to hold messages?
    {:noreply, assign(socket, :messages, [message])}
  end
end
