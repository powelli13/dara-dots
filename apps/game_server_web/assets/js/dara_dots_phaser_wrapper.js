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
      movableDots,
      runnerPieces}) => {
      yellowGraphics.clear();

      drawBoardState(dots);

      if (redAlphaLinker !== undefined)
        updateLinkerCoord(redAlphaLinker, topAlphaCoord);
      if (redBetaLinker !== undefined)
        updateLinkerCoord(redBetaLinker, topBetaCoord);
      if (blueAlphaLinker !== undefined)
        updateLinkerCoord(blueAlphaLinker, botAlphaCoord);
      if (blueBetaLinker !== undefined)
        updateLinkerCoord(blueBetaLinker, botBetaCoord);

      drawRunnerPieces(runnerPieces, yellowGraphics);

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

    const triangleBuffer = 12;

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
    let yellowGraphics;
    let movableDotGraphics;
    let emptyDot;

    // Sprites for Pieces
    let redAlphaLinker;
    let redBetaLinker;
    let blueAlphaLinker;
    let blueBetaLinker;
    let highlightDots = {};
    let highlightCoords = {};

    let game = new Phaser.Game(config);

    function preload () {
      this.load.image("background", "game_images/background.jpg");
      this.load.image("red_linker", "game_images/red_linker.png");
      this.load.image("blue_linker", "game_images/blue_linker.png");
      this.load.image("highlight_dot", "game_images/highlight_dot.png");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      grayGraphics = this.add.graphics({ fillStyle: {color: 0xd3d3d3 } });
      yellowGraphics = this.add.graphics({ fillStyle: {color: 0xffff00} });
      movableDotGraphics = this.add.graphics({ fillStyle: {color: 0xffdf33, alpha: 0.5} });

      // Setup Pieces
      redAlphaLinker = this.add.sprite(0, 0, "red_linker").setInteractive();
      redAlphaLinker.on("pointerup", function (_) {
        gameChannel.push("select_piece", {"piece": "top_alpha"})
          .receive("error", e => e.console.log(e));
      });

      redBetaLinker = this.add.sprite(0, 0, "red_linker").setInteractive();
      redBetaLinker.on("pointerup", function (_) {
        gameChannel.push("select_piece", {"piece": "top_beta"})
          .receive("error", e => e.console.log(e));
      });

      blueAlphaLinker = this.add.sprite(0, 0, "blue_linker").setInteractive();
      blueAlphaLinker.on("pointerup", function (_) {
        gameChannel.push("select_piece", {"piece": "bot_alpha"})
          .receive("error", e => e.console.log(e));
      });

      blueBetaLinker = this.add.sprite(0, 0, "blue_linker").setInteractive();
      blueBetaLinker.on("pointerup", function (_) {
        gameChannel.push("select_piece", {"piece": "bot_beta"})
          .receive("error", e => e.console.log(e));
      });

      // Create four sprites to use when highlighting squares
      for (let i = 0; i < 4; i++) {
        // TODO set the alpha to remove hight background
        let hDot = this.add.sprite(-24, -24, "highlight_dot").setInteractive();
        hDot.on("pointerup", function (_) {
          if (highlightCoords[i] !== undefined && highlightCoords[i].length == 2) {
            gameChannel.push("submit_move",
                {"row": highlightCoords[i][0], "col": highlightCoords[i][1]})
              .receive("error", e => e.console.log(e));
          }
        });

        // TODO will need to send the correct coordinates when clicked
        // may need to use the dots for this
        highlightDots[i] = hDot;
        highlightCoords[i] = [];
      }

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

    function updateLinkerCoord(linkerSprite, coord) {
      const x = rowCoordinateToPixels(coord[1]);
      const y = colCoordinateToPixels(coord[0]);

      // TODO update link if applicable

      linkerSprite.x = x;
      linkerSprite.y = y;
    }

    function drawRunnerPieces(runnerCoords, graphics) {
      runnerCoords.forEach((r, _) => {
        const cx = rowCoordinateToPixels(r[1]);
        const cy = colCoordinateToPixels(r[0]);

        const x1 = cx - triangleBuffer;
        const y1 = cy + triangleBuffer;
        const x2 = cx + triangleBuffer;
        const y2 = cy + triangleBuffer;
        const x3 = cx;
        const y3 = cy - triangleBuffer;

        graphics.fillTriangle(x1, y1, x2, y2, x3, y3);
      });
    }

    function highlightMovableDots(movableDots) {
      // Used to move unused highlight dot sprites offscreen
      let lastUsedHighlightIndex = -1;

      movableDots.forEach((v, i) => {
        lastUsedHighlightIndex = i;
        const row = v[0];
        const col = v[1];
        const x = rowCoordinateToPixels(row);
        const y = colCoordinateToPixels(col);

        if (i < 4) {
          let hDot = highlightDots[i];
          hDot.x = x;
          hDot.y = y;

          highlightCoords[i] = [row, col];
        }
      });

      // We didn't use all sprites, or there were no movable dots
      if (lastUsedHighlightIndex < 3 || lastUsedHighlightIndex == -1) {
        for (let i = lastUsedHighlightIndex + 1; i < 4; i++) {
          let hDot = highlightDots[i];
          hDot.x = -24;
          hDot.y = -24;

          highlightCoords[i] = [];
        }
      }
    }

    // The server stores object positions as relative percentages
    // of the total game space. These functions are used to convert
    // server values into the percentage for the client board position.
    function rowCoordinateToPixels(rowCoord) {
      return (boardWidth - boardBuffer) * (rowCoord / 5);
    }

    function colCoordinateToPixels(colCoord) {
      //return (boardHeight - boardBuffer) * (colCoord / 5);
      let diff = (boardHeight - boardBuffer) * (colCoord / 5);
      return boardHeight - diff;
    }
  }
};

export default DaraDotsPhaserWrapper;
