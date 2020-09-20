
// Object used to send player inputs to the server
// and receive updates using a websocket.
let Game = {
  init(socket, urlParam) {
    var params = new URLSearchParams(document.location.search);
    if (!params.has(urlParam)) { return; }
    if (!document.getElementById("game-message-container")) { return; }

    socket.connect();

    this.onReady(socket, params.get(urlParam));
  },

  onReady(socket, gameId) {
    console.log("game ready!");
    let messageContainer = document.getElementById("game-message-container");
    let submitMove = document.getElementById("submit-move");

    let gameChannel = socket.channel("game:" + gameId, () => {
      let username = window.localStorage.getItem("dara-username");
      return username 
        ? {username: username}
        : {username: "anon" + Math.floor(Math.random() * 1000)};
    });

    // Submit the players move to the server
    submitMove.addEventListener("click", e => {
      let move = "";
      let moveOptions = document.getElementsByName("move");

      for (let i = 0; i < moveOptions.length; i++) {
        if (moveOptions[i].checked) {
          move = moveOptions[i].value;
        }
      }

      // TODO also need to send game id and player name here
      // Or should the game Id be on the socket?
      let payload = {move: move};
      gameChannel.push("player_move", payload)
        .receive("error", e => e.console.log(e));
    });

    gameChannel.on("player_move", (resp) => {
      this.renderAnnotation(messageContainer, resp);
    });

    gameChannel.join()
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

  renderAnnotation(messageContainer, {message}) {
    let template = document.createElement("div");
    template.innerHTML = `${this.esc(message)}`;

    messageContainer.appendChild(template);
    messageContainer.scrollTop = messageContainer.scrollHeight;
  }
};

export default Game;