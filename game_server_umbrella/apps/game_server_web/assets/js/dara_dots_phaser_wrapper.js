import Phaser from "phaser";

let DaraDotsPhaserWrapper = {
  init(socket, gameElemId) {
    // Ensure that we only load Dara Dots Phaser on the correct pages
    let gameElement = document.getElementById(gameElemId);
    if (gameElement == null) { return; }

    //const params = new URLSearchParams(document.location.search);
    //if (!params.has('id')) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, "1");// params.get('id'));
  },

  onReady(socket, gameId) {
    let daraDotsChannel = socket.channel(`dara_dots_game:${gameId}`, () => {
      return {};
    });

    this.initPhaserGame(daraDotsChannel);
  },

  initPhaserGame(gameChannel) {
    // Setup channel listeners
    gameChannel.on("game_state",
    ({dots, circleCoord}) => {
      drawBoardState(dots);
      drawCirclePiece(circleCoord);
    });

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

    // Setup game objects
    let grayGraphics;
    let blueGraphics;
    let emptyDot;

    let game = new Phaser.Game(config);

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      grayGraphics = this.add.graphics({ fillStyle: {color: 0xd3d3d3 } });
      blueGraphics = this.add.graphics({ fillStyle: {color: 0x0080ff } });

      //emptyDot = new Phaser.Geom.Circle(250, 250, 2);
      //grayGraphics.fillCircleShape(emptyDot);

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function drawBoardState(dots) {
      grayGraphics.clear();

      dots.forEach((v, i) => {
        // TODO delineate type of dots using v[2]
        const x = percentWidthToPixels(v[0]);
        const y = percentHeightToPixels(v[1]);

        grayGraphics.fillCircleShape(
          new Phaser.Geom.Circle(x, y, 2)
        );
      });
    }

    function drawCirclePiece(circleCoord) {
      blueGraphics.clear();

      const x = percentWidthToPixels(circleCoord[0]);
      const y = percentHeightToPixels(circleCoord[1]);

      blueGraphics.fillCircleShape(
        new Phaser.Geom.Circle(x, y, 12)
      );
    }

    // The server stores object positions as relative percentages
    // of the total game space. These functions are used to convert
    // server values into the percentage for the client board position.
    function percentWidthToPixels(percentage) {
      return boardWidth * percentage;
    }

    function percentHeightToPixels(percentage) {
      return boardHeight * percentage;
    }
  }
};

export default DaraDotsPhaserWrapper;
