import {Presence} from "phoenix";
import Player from "./player";

// Object used to connect to a lobby channel using
// a socket and facilitate chatting messages.
let LobbyChat = {
  init(socket, element) {
    if (!element) { return; }

    socket.connect();

    Player.init("video-player-id", "jHefeA-hyMA", () => console.log("video player ready!"));
    // The location may be of the form /lobby/{id}
    // or /lobby?id={id} depending on how the player joined
    // both are supported
    let lobbyId = new URL(document.location).pathname.split("/")[2];
    console.log(`Lobby id is: ${lobbyId}`);

    const searchParams = new URLSearchParams(document.location.search);
    let playerName = searchParams.get("player_name");

    if (lobbyId === undefined) {
      lobbyId = searchParams.get("lobby_id");
    }

    // TODO maybe navigate away here and let them know it's a problem
    if (lobbyId === undefined) {
      return;
    }

    this.onReady(socket, lobbyId, playerName);
  },

  // Prepare resources and event listeners for lobby chat.
  onReady(socket, lobbyId, playerName) {
    // Controls used for the lobby chatting
    const chatContainer = document.getElementById("lobby-chat-container");
    const chatInput = document.getElementById("lobby-chat-input");
    const postButton = document.getElementById("lobby-chat-submit");

    // Elements used to display users in lobby and
    // the participant list
    const userList = document.getElementById("user-list");
    const participantListContainer = document.getElementById("lobby-participant-list");

    // Controls to control starting and advancing the Lip Sync performance
    const startPerformanceButton = document.getElementById("start-performance-button");
    const nextPerformerButton = document.getElementById("next-performer-button");

    // Hidden input for the lobby id in the register team form
    let lobbyIdInput = document.getElementById("hidden-lobby-id");
    lobbyIdInput.value = lobbyId;

    let lobbyChannel = socket.channel(`lobby:${lobbyId}`, () => {
      return playerName 
        ? {username: playerName}
        : {username: "anon" + Math.floor(Math.random() * 1000)};
    });

    let presence = new Presence(lobbyChannel);

    presence.onSync(() => {
      userList.innerHTML = presence.list((id, metas) => {
        return `<li>${this.esc(id)}</li>`;
      }).join("");
    });
    
    // Send chat message to the server.
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
        console.log(resp.new_id);
        Player.player.loadVideoById(resp.new_id);
      }
    });

    // Start the Lip Sync performance
    startPerformanceButton.addEventListener("click", e => {
      lobbyChannel.push("start_performance", {})
        .receive("error", e => e.console.log(e));

      startPerformanceButton.setAttribute("disabled", "disabled");
    });

    // Advance the Lip Sync queue to the next performing team
    nextPerformerButton.addEventListener("click", e => {
      lobbyChannel.push("next_performer", {})
        .receive("error", e => e.console.log(e));
    });

    //lobbyChannel.on("game_started", (resp) => {
    //  this.navigateToGame(resp);
    //});

    // Receive and render a new chat message.
    lobbyChannel.on("new_msg", (resp) => {
      this.renderAnnotation(chatContainer, resp);
    });

    // Receive updated list of Lip Sync participants
    lobbyChannel.on("participant_list", (resp) => {
      this.renderParticipantList(participantListContainer, resp);
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
  },

  // Display the updated list of participants currently waiting
  // in the Lip Sync queue.
  // The updated_list is a JSON object of name -> videoId
  renderParticipantList(participantListContainer, {updated_list}) {
    participantListContainer.innerHTML = "";

    for (const name in updated_list) {
      let template = document.createElement("div");
      template.innerHTML = `<b>${name}</b>`;

      participantListContainer.appendChild(template);
    }
  }
};

export default LobbyChat;
