// Object used to connect to a lobby channel using
// a socket and facilitate chatting messages.
let LobbyChat = {
  init(socket, element) {
    if (!element) { return; }

    socket.connect();

    this.onReady(socket);
  },

  // Prepare resources and event listeners for lobby chat.
  onReady(socket) {
    let chatContainer = document.getElementById("lobby-chat-container");
    let chatInput = document.getElementById("lobby-chat-input");
    let postButton = document.getElementById("lobby-chat-submit");
    let lobbyChannel = socket.channel("lobby:1", () => {
      return {random_id:  Math.floor((Math.random() * 1000))};
    });

    // Send message to the server.
    postButton.addEventListener("click", e => {
      let payload = {message: chatInput.value};
      lobbyChannel.push("new_msg", payload)
        .receive("error", e => e.console.log(e));
      chatInput.value = "";
    });

    // Receive and render a new chat message.
    lobbyChannel.on("new_msg", (resp) => {
      this.renderAnnotation(chatContainer, resp);
    });
    
    // Join the lobby chat channel.
    lobbyChannel.join()
      .receive("ok", () => {
        // TODO welcome message maybe?
        return;
      })
      .receive("error", reason => console.log("join failed", reason));
  },

  // Used to safely escape message strings to avoid injection on the page.
  esc(str) {
    let div = document.createElement("div");
    div.appendChild(document.createTextNode(str));

    return div.innerHTML;
  },

  // Display a new message in the chat container.
  renderAnnotation(chatContainer, {user_id, message}) {
    let template = document.createElement("div");
    template.innerHTML = `
      <b>anon-${user_id}</b>: ${this.esc(message)}
    `;

    chatContainer.appendChild(template);
    chatContainer.scrollTop = chatContainer.scrollHeight;
  }
};

export default LobbyChat;