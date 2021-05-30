import Phaser from "phaser";

let PongPhaserWrapper = {
  init(socket, gameElemId) {
    // TODO put game Id to connect to channel

    // Ensure that we only load Pong Phaser on the correct pages
    let gameElement = document.getElementById(gameElemId);
    if (gameElement == null) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket);
  },

  onReady(socket) {
    //var ticTacToeGameChannel = socket.channel("ttt_game:" + gameId, () => {
      //let username = window.localStorage.getItem("player_name");
      //return {username: username};
    //});

    //this.initPhaserGame(gameChannel)
    this.initPhaserGame();
  },


  initPhaserGame() {
    // Setup game rendering and piece tools
    const boardWidth = 500;
    const boardHeight = 500;

    // Setup Phaser game
    var config = {
      type: Phaser.AUTO,
      width: boardWidth,
      height: boardHeight,
      physics: {
        default: "arcade",
        arcade: {
          gravity: { y: 0 }
        }
      },
      scene: {
        preload: preload,
        create: create,
        update: update
      }
    };

    var game = new Phaser.Game(config);

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }
  }
};

export default PongPhaserWrapper;
