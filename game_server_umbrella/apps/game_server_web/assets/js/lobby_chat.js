import {Presence} from "phoenix";

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
    const joinQueueButton = document.getElementById("join-game-queue-button");
    const leaveQueueButton = document.getElementById("leave-game-queue-button");
    const userList = document.getElementById("user-list");

    // Disable leave queue on page load.
    leaveQueueButton.disabled = true;

    let lobbyChannel = socket.channel(
      `lobby_chat:${chatContainer.dataset.lobbyName}`,
      () => {
        const playerName = window.localStorage.getItem("player_name") ?? "";
        return {username: playerName};
      });

    // Presence will display the names of users in the chat lobby
    let presence = new Presence(lobbyChannel);
    presence.onSync(() => {
      userList.innerHTML = presence.list((username, _) => {
        return `<li>${username}</li>`;
      }).join("");
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
      leaveQueueButton.disabled = false;
    });

    // Remove the player from the queue.
    leaveQueueButton.addEventListener("click", e => {
      lobbyChannel.push("leave_queue", {})
        .receive("error", e => e.console.log(e));
      leaveQueueButton.disabled = true;
      joinQueueButton.disabled = false;
    });

    // Leave the queue when the user leaves the lobby
    // TODO this isn't working. it will write the console logs but not push 
    // leave_queue to the server
    // After debugging JavaScript in the browser I found that lobbyChannel.socket.unloaded is false
    // in the above join/leave queue and true here, so the socket is already unloaded
    // I will try to intercept the channel disconnect on the server side, and remove
    // their ID from the queue that way.
    window.addEventListener("beforeunload", e => {
      console.log("leaving queue and page");
      lobbyChannel.push("leave_queue", {})
        .receive("error", e => e.console.log(e));
      console.log("successfully left queue");
    });

    lobbyChannel.on("new_msg", (resp) => {
      this.renderAnnotation(chatContainer, resp);
    });

    lobbyChannel.on("game_started", (resp) => {
      this.navigateToGame(resp);
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
  navigateToGame({game_url}) {
    console.log('navigating player to:');
    console.log(game_url);
    window.location.replace(`/${game_url}`);
  }
};

export default GenLobbyChat;