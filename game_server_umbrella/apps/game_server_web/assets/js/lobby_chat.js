// A generic lobby chat channel which can be used
// for a variety of games. The template chat
// container's element must have a data-lobby-name
// attribute to specific which lobby should be
// connected to.
let GenLobbyChat = {
  init(socket) {
    // Only connect if the chat container is on the page
    // TODO change the lobby.js file to not overlap IDs
    const element = document.getElementById("gen-lobby-chat-container");
    if (!element) { return; }
    if (!element.dataset.lobbyName) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, element);
  },

  onReady(socket, chatContainer) {
    const chatInput = document.getElementById("gen-lobby-chat-input");
    const postButton = document.getElementById("gen-lobby-chat-submit");

    let lobbyChannel = socket.channel(
      `lobby_chat:${chatContainer.dataset.lobbyName}`,
      () => {
        const playerName = window.localStorage.getItem("player_name") ?? "";
        return {username: playerName};
      });

    // Send chat message
    postButton.addEventListener("click", e => {
      let payload = {message: chatInput.value};
      lobbyChannel.push("new_msg", payload)
        .receive("error", e => e.console.log(e));

      chatInput.value = "";
    });

    lobbyChannel.on("new_msg", (resp) => {
      this.renderAnnotation(chatContainer, resp);
    });

    // Join the lobby chat channel.
    lobbyChannel.join()
      .receive("ok", () => {
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
  renderAnnotation(chatContainer, {username, message}) {
    let template = document.createElement("div");
    template.innerHTML = `
      <b>${username}</b>: ${this.esc(message)}
    `;

    chatContainer.appendChild(template);
    chatContainer.scrollTop = chatContainer.scrollHeight;
  }
};

export default GenLobbyChat;