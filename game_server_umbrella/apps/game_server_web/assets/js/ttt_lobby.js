// Object used to connect to the RPS Game lobby channel using
// a socket and facilitate chatting messages and joining the Game queue.
let TttLobbyChat = {
  init(socket, element) {
    if (!element) { return; }

    socket.connect();

    this.onReady(socket);
  },

  // Prepare resources and event listeners for lobby chat.
  onReady(socket) {
    // Controls used for the lobby chatting
    const joinQueueButton = document.getElementById("join-game-queue-button");

    let lobbyChannel = socket.channel(`ttt_lobby:1`, () => {
      const username = "anon" + Math.floor(Math.random() * 1000);
      window.localStorage.setItem("dara-username", username);
      return {username: username};
    });

    // Add the player to the queue.
    joinQueueButton.addEventListener("click", e => {
      lobbyChannel.push("join_queue", {player_name: window.localStorage.getItem("dara-username")})
      .receive("error", e => e.console.log(e));
      joinQueueButton.disabled = true;
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

  // Navigate the user to their newly started game.
  navigateToGame({username, game_id}) {
    // TODO improve this by pushing to individual sockets rather than checking usernames
    if (username == window.localStorage.getItem("dara-username")) {
      window.location.replace(`/ttt-game?id=${game_id}`);
    }
  }
};

export default TttLobbyChat;
