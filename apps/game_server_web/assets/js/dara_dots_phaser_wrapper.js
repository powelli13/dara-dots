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
    ({
      dots,
      topAlphaCoord,
      topBetaCoord,
      botAlphaCoord,
      botBetaCoord,
      movableDots}) => {
      blueGraphics.clear();
      redGraphics.clear();

      drawBoardState(dots);
      drawLinkerPiece(topAlphaCoord, redGraphics);
      drawLinkerPiece(topBetaCoord, redGraphics);
      drawLinkerPiece(botAlphaCoord, blueGraphics);
      drawLinkerPiece(botBetaCoord, blueGraphics);
      highlightMovableDots(movableDots);
    });

    gameChannel.join()
      .receive("ok", (resp) => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));

    // Setup display dimension
    const boardWidth = 500;
    const boardHeight = 500;
    const boardBuffer = 75;

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
    let redGraphics;
    let blueGraphics;
    let movableDotGraphics;
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
      redGraphics = this.add.graphics({ fillStyle: {color: 0xe60000} });
      movableDotGraphics = this.add.graphics({ fillStyle: {color: 0xffdf33, alpha: 0.5} });

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function drawBoardState(dots) {
      grayGraphics.clear();

      dots.forEach((v, i) => {
        const x = rowCoordinateToPixels(v[1]);
        const y = colCoordinateToPixels(v[0]);

        grayGraphics.fillCircleShape(
          new Phaser.Geom.Circle(x, y, 4)
        );
      });
    }

    function drawLinkerPiece(linkerCoord, graphics) {
      const x = rowCoordinateToPixels(linkerCoord[1]);
      const y = colCoordinateToPixels(linkerCoord[0]);

      graphics.fillRectShape(
        new Phaser.Geom.Rectangle(x-12, y-12, 24, 24)
      );
    }

    function highlightMovableDots(movableDots) {
      movableDotGraphics.clear();

      movableDots.forEach((v, i) => {
        const x = rowCoordinateToPixels(v[0]);
        const y = colCoordinateToPixels(v[1]);

        movableDotGraphics.fillCircleShape(
          new Phaser.Geom.Circle(x, y, 8)
        );
      });
    }

    // The server stores object positions as relative percentages
    // of the total game space. These functions are used to convert
    // server values into the percentage for the client board position.
    function rowCoordinateToPixels(rowCoord) {
      return (boardWidth - boardBuffer) * (rowCoord / 5);
    }

    function colCoordinateToPixels(colCoord) {
      return (boardHeight - boardBuffer) * (colCoord / 5);
    }
  }
};

export default DaraDotsPhaserWrapper;
