import {Presence} from "phoenix";
import Player from "./player";

// Object used to connect to a lobby channel using
// a socket and facilitate chatting messages.
let LobbyChat = {
  init(socket, element) {
    if (!element) { return; }

    socket.connect();

    Player.init("video-player-id", "8jTjNMkWOzM", () => console.log("video player ready!"));
    // Expecting the location to be of the form /lobby/{id}
    const lobbyId = new URL(document.location).pathname.split("/")[2];

    this.onReady(socket, lobbyId);
  },

  // Prepare resources and event listeners for lobby chat.
  onReady(socket, lobbyId) {
    let chatContainer = document.getElementById("lobby-chat-container");
    let chatInput = document.getElementById("lobby-chat-input");
    let postButton = document.getElementById("lobby-chat-submit");
    let userList = document.getElementById("user-list");
    let lobbyChannel = socket.channel(`lobby:${lobbyId}`, () => {
      let username = window.localStorage.getItem("dara-username");
      return username 
        ? {username: username}
        : {username: "anon" + Math.floor(Math.random() * 1000)};
    });

    let presence = new Presence(lobbyChannel);

    presence.onSync(() => {
      userList.innerHTML = presence.list((id, metas) => {
        return `<li>${this.esc(id)}</li>`;
      }).join("");
    });
    
    // Send message to the server.
    postButton.addEventListener("click", e => {
      let payload = {message: chatInput.value};
      lobbyChannel.push("new_msg", payload)
      .receive("error", e => e.console.log(e));
      chatInput.value = "";
    });

    // Join the queue for rock paper scissors
    // let joinQueue = document.getElementById("join-queue-button");
    // joinQueue.addEventListener("click", e => {
    //   joinQueue.setAttribute("disabled", "disabled");
    //   lobbyChannel.push("join_queue", {})
    //     .receive("error", e => e.console.log(e));
    // });

    // Test to send a new video ID for the player and update it
    let updateVideoId = document.getElementById("update-video-button");
    let videoIdInput = document.getElementById("video-id-input");

    updateVideoId.addEventListener("click", e => {
      lobbyChannel.push("update_video", {new_id: videoIdInput.value})
        .receive("error", e => e.console.log(e));
    });

    lobbyChannel.on("update_video", (resp) => {
      if (Player.player != null) {
        Player.player.loadVideoById(resp.new_id);
      }
    });

    lobbyChannel.on("game_started", (resp) => {
      this.navigateToGame(resp);
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

  // Navigate the user to their newly started game.
  navigateToGame({username, game_id}) {
    // TODO improve this by pushing to individual sockets rather than checking usernames
    if (username == window.localStorage.getItem("dara-username")) {
      window.location.replace(`/game?id=${game_id}`);
    }
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

export default LobbyChat;
