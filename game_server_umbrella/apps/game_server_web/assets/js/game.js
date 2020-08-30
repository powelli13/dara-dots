
// Object used to send player inputs to the server
// and receive updates using a websocket.
let Game = {
  init(socket, element) {
    // TODO change
    if (element != "game_id") { return; }

    socket.connect();
  }
};

export default Game;