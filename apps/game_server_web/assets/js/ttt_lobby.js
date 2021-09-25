// Object used to connect to the RPS Game lobby channel using
// a socket and facilitate chatting messages and joining the Game queue.
let TttLobbyChat = {
  init(socket, element) {
    if (!element) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket);
  },

  // Prepare resources and event listeners for lobby chat.
  onReady(socket) {
    // Controls used for the lobby chatting
    const chatContainer = document.getElementById("ttt-lobby-chat-container");
    const chatInput = document.getElementById("lobby-chat-input");
    const postButton = document.getElementById("lobby-chat-submit");
    const joinQueueButton = document.getElementById("join-game-queue-button");

    let lobbyChannel = socket.channel(`ttt_lobby:1`, () => {
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

    // Add the player to the queue.
    joinQueueButton.addEventListener("click", e => {
      lobbyChannel.push("join_queue", {})
      .receive("error", e => e.console.log(e));
      joinQueueButton.disabled = true;
    });

    lobbyChannel.on("game_started", (resp) => {
      this.navigateToGame(resp);
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
  },

  // Navigate the user to their newly started game.
  navigateToGame({username, game_id}) {
    // TODO improve this by pushing to individual sockets rather than checking usernames
    if (username == window.localStorage.getItem("player_name")) {
      window.location.replace(`/ttt-game?ttt_id=${game_id}`);
    }
  }
};

export default TttLobbyChat;
