import Phaser from "phaser";

let DaraDotsPhaserWrapper = {
  init(socket, gameElemId) {
    // Ensure that we only load Dara Dots Phaser on the correct pages
    let gameElement = document.getElementById(gameElemId);
    if (gameElement == null) { return; }

    //const params = new URLSearchParams(document.location.search);
    //if (!params.has('id')) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, "");// params.get('id'));
  },

  onReady(socket, gameId) {
    let daraDotsChannel = socket.channel(`dara_dots_game:${gameId}`, () => {
      return {};
    });

    this.initPhaserGame(daraDotsChannel);
  },

  initPhaserGame(gameChannel) {
    // Setup channel listeners

    gameChannel.join()
      .receive("ok", (resp) => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));

    // Setup display dimension
    const boardWidth = 500;
    const boardHeight = 500;

    // Setup Phaser game
    let config = {
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

    let game = new Phaser.Game(config);

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

export default DaraDotsPhaserWrapper;
