defmodule GameServerWeb.LipSyncLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  alias GameServerWeb.Presence

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    connected = connected?(socket)

    if connected do
      PubSub.subscribe(GameServer.PubSub, "lipsync:test")
    end

    {:ok,
     socket
     |> assign(:connected, connected)
     |> assign(:draft_message, "")
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
    <form phx-submit="send_message">
      <textarea rows="2" placeholder="Chat" name="message" value="<%= @draft_message %>">
      </textarea>
      <button type="submit">
        Send
      </buton>
    </form>
    """
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
