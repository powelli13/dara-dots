import Phaser from "phaser";
import daraDotsBoardConstants from "./dara_dots_board_setup";

let DaraDotsPhaserWrapper = {
  init(socket, gameElemId) {
    // Ensure that we only load Dara Dots Phaser on the correct pages
    const gameElement = document.getElementById(gameElemId);
    if (gameElement == null) { return; }

    const params = new URLSearchParams(document.location.search);
    if (!params.has('id')) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, params.get('id'));
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
      topPlayerScore,
      botPlayerScore,
      movableDots,
      linkableDots,
      runnerPieces,
      links,
      playerMessage,
      currentTurn}) => {
      console.log(`The player message: ${playerMessage}`);

      // Consider changing this scoreboard to use Phaser cool looking text
      document.getElementById('scoreboard').innerText =
        `Top ${topPlayerScore} - Bot ${botPlayerScore} Current Turn: ${currentTurn}`;

      yellowGraphics.clear();

      drawBoardState(dots);
      drawLinks(links, yellowGraphics);

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

      highlightLinkableDots(linkableDots);
    });

    gameChannel.join()
      .receive("ok", (resp) => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));


    // Setup Phaser game
    let config = {
      type: Phaser.AUTO,
      width: daraDotsBoardConstants.boardWidth,
      height: daraDotsBoardConstants.boardHeight,
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

    // Sprites for Pieces
    let redAlphaLinker;
    let redBetaLinker;
    let blueAlphaLinker;
    let blueBetaLinker;

    // For creating runner pieces
    let createRunnerButtons = {};
    let createRunnerCoords = {};

    // Used for highlighting movable coordinates when a linker is selected
    let highlightDots = {};
    let highlightCoords = {};

    // Use for showing linkable coords when a linker is selected
    let highlightLinkable = {};
    let highlightLinkableCoords = {};

    let linkLine;

    let greenGraphics;
    let follower;
    let path;
    let timedEvent;
    let testLinePosition = 'left'
    let line1;
    let line2;
    let testLineCoords;

    let game = new Phaser.Game(config);

    function preload () {
      this.load.image("background", "game_images/background.jpg");
      this.load.image("red_linker", "game_images/red_linker.png");
      this.load.image("blue_linker", "game_images/blue_linker.png");
      this.load.image("highlight_dot", "game_images/highlight_dot.png");
      this.load.image("highlight_linkable", "game_images/highlight_linkable.png");
      this.load.image("create_runner", "game_images/create_runner.png");
    }

    function create () {
      // TODO move game board sprite initialization to another file if possible
      // Only load the Phaser assets on certain pages
      this.add.image(daraDotsBoardConstants.boardWidth, daraDotsBoardConstants.boardHeight, "background");

      grayGraphics = this.add.graphics({ fillStyle: {color: 0xd3d3d3 } });
      yellowGraphics = this.add.graphics(
        {
          fillStyle: {color: 0xffff00},
          lineStyle: { width: 4, color: 0xffff00 }
        });
      movableDotGraphics = this.add.graphics({ fillStyle: {color: 0xffdf33, alpha: 0.5} });
      linkLine = new Phaser.Geom.Line(
        colCoordinateToPixels(1),
        rowCoordinateToPixels(1),
        colCoordinateToPixels(2),
        rowCoordinateToPixels(1)
      );

      greenGraphics = this.add.graphics({ fillStyle: {color: 0x00cc00}});

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

      // Allow the user to create triangles
      for (let i = 0; i < 5; i++) {
        let [xCoord, yCoord] = coordinateToPixels([5, i + 1]);

        // TODO will need to distinguish between bottom and top player when allowing them to create runners
        let runnerButton = this.add.sprite(xCoord, yCoord + 24, "create_runner").setInteractive();
        runnerButton.on("pointerup", function (_) {
          gameChannel.push("place_runner", {"col": i + 1, "row": 5})
            .receive("error", e => e.console.log(e));
        });

        createRunnerButtons[i] = runnerButton;
      }

      // Create four sprites to use when highlighting squares
      for (let i = 0; i < 4; i++) {
        const hDot = this.add.sprite(-24, -24, "highlight_dot").setInteractive();
        hDot.on("pointerup", function (_) {
          if (highlightCoords[i] !== undefined && highlightCoords[i].length == 2) {
            gameChannel
              .push("submit_move",
                {"row": highlightCoords[i][0], "col": highlightCoords[i][1]})
              .receive("error", e => e.console.log(e));
          }
        });

        highlightDots[i] = hDot;
        highlightCoords[i] = [];
      }

      // Create two sprites to indicate which nodes are linkable
      for (let i = 0; i < 2; i++) {
        let linkable = this.add.sprite(-24, -24, "highlight_linkable").setInteractive();
        linkable.on("pointerup", function (_) {
          if (highlightLinkableCoords[i] !== undefined && highlightLinkableCoords[i].length == 2) {
            gameChannel
              .push("submit_link_move",
                {"row": highlightLinkableCoords[i][0], "col": highlightLinkableCoords[i][1]})
              .receive("error", e => e.console.log(e));
          }
        });

        highlightLinkable[i] = linkable;
        highlightLinkableCoords[i] = [];
      }

      // Working on a basic path following object
      follower = { t: 0, vec: new Phaser.Math.Vector2() };


      path = this.add.path();
      //timedEvent = this.time.delayedCall(3000, swapLines, [], this);


      line1 = new Phaser.Curves.Line([ 100, 100, 500, 200 ]);
      line2 = new Phaser.Curves.Line([ 200, 300, 600, 500 ]);

      testLineCoords = [
        {
          start: [3, 3],
          end: [3, 4]
        },
        {
          start: [3, 4],
          end: [3, 5]
        },
        {
          start: [3, 5],
          end: [2, 5]
        }];

      path.add(line2);
      populateLinesFromCoords(path, testLineCoords);

      this.tweens.add({
          targets: follower,
          t: 1,
          ease: 'Linear',
          duration: 4000,
          yoyo: true,
          repeat: -1
      });

      this.input.mouse.disableContextMenu();
    }

    function update() {
      greenGraphics.clear();
      path.draw(greenGraphics);
      path.getPoint(follower.t, follower.vec);

      let x1 = follower.vec.x - daraDotsBoardConstants.triangleBuffer;
      let y1 = follower.vec.y + daraDotsBoardConstants.triangleBuffer;
      let x2 = follower.vec.x + daraDotsBoardConstants.triangleBuffer;
      let y2 = follower.vec.y + daraDotsBoardConstants.triangleBuffer;
      let x3 = follower.vec.x;
      let y3 = follower.vec.y - daraDotsBoardConstants.triangleBuffer;
      greenGraphics.fillTriangle(x1, y1, x2, y2, x3, y3);
    }

    function populateLinesFromCoords(path, coords) {
      path.destroy();

      coords.forEach(se => {
        const [xs, ys] = coordinateToPixels(se.start);
        const [xe, ye] = coordinateToPixels(se.end);

        path.add(new Phaser.Curves.Line([xs, ys, xe, ye]));
      });
    }

    function swapLines() {
      path.destroy();
      if (testLinePosition === 'left') {
        path.add(line1);
        testLinePosition = 'right';
      } else {
        path.add(line2);
        testLinePosition = 'left';
      }

      timedEvent = this.time.delayedCall(3000, swapLines, [], this);
    }

    function drawBoardState(dots) {
      grayGraphics.clear();

      dots.forEach(v => {
        let [x, y] = coordinateToPixels(v);

        grayGraphics.fillCircleShape(
          new Phaser.Geom.Circle(x, y, 4)
        );
      });
    }

    function updateLinkerCoord(linkerSprite, coord) {
      let [x, y] = coordinateToPixels(coord);

      linkerSprite.x = x;
      linkerSprite.y = y;
    }

    function drawLinks(coords, graphics) {
      coords.forEach((c, _) => {
        let [x1, y1] = coordinateToPixels(c[0]);
        let [x2, y2] = coordinateToPixels(c[1]);

        linkLine.x1 = x1;
        linkLine.x2 = x2;
        linkLine.y1 = y1;
        linkLine.y2 = y2;

        graphics.strokeLineShape(
          linkLine
        );
      });
    }

    function drawRunnerPieces(runnerPieces, graphics) {
      runnerPieces.forEach((r, _) => {
        let [cx, cy] = coordinateToPixels(r.coords);

        let x1 = cx - daraDotsBoardConstants.triangleBuffer;
        let y1 = cy + daraDotsBoardConstants.triangleBuffer;
        let x2 = cx + daraDotsBoardConstants.triangleBuffer;
        let y2 = cy + daraDotsBoardConstants.triangleBuffer;
        let x3 = cx;
        let y3 = cy - daraDotsBoardConstants.triangleBuffer;

        if (r.facing == "up") {
          x1 = cx - daraDotsBoardConstants.triangleBuffer;
          y1 = cy - daraDotsBoardConstants.triangleBuffer;
          x2 = cx + daraDotsBoardConstants.triangleBuffer;
          y2 = cy - daraDotsBoardConstants.triangleBuffer;
          x3 = cx;
          y3 = cy + daraDotsBoardConstants.triangleBuffer;
        }

        graphics.fillTriangle(x1, y1, x2, y2, x3, y3);
      });
    }

    function highlightMovableDots(movableDots) {
      // Used to move unused highlight dot sprites offscreen
      let lastUsedHighlightIndex = -1;

      movableDots.forEach((v, i) => {
        lastUsedHighlightIndex = i;
        let [x, y] = coordinateToPixels(v);

        if (i < 4) {
          let hDot = highlightDots[i];
          hDot.x = x;
          hDot.y = y;

          highlightCoords[i] = [v[0], v[1]];
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

    function highlightLinkableDots(coords) {
      // Used to move unused highlight dot sprites offscreen
      let lastUsedHighlightIndex = -1;

      coords.forEach((c, i) => {
        let [x, y] = coordinateToPixels(c);
        lastUsedHighlightIndex = i;

        // Add the buffer to move it the linkable sprite off to show both
        highlightLinkable[i].x = x + daraDotsBoardConstants.linkHighlightBuffer;
        highlightLinkable[i].y = y + daraDotsBoardConstants.linkHighlightBuffer;

        highlightLinkableCoords[i] = [c[0], c[1]];
      });

      // We didn't use the second sprite, or there were no linkable dots
      if (lastUsedHighlightIndex == 0 || lastUsedHighlightIndex == -1) {
        for (let i = lastUsedHighlightIndex + 1; i < 2; i++) {
          let hDot = highlightLinkable[i];
          // TODO this and line 288 above are breaking becausee this is a fragile and gross fix, improve this
          hDot.x = -24;
          hDot.y = -24;

          highlightLinkableCoords[i] = [];
        }
      }
    }

    // The server stores object positions as relative percentages
    // of the total game space. These functions are used to convert
    // server values into the percentage for the client board position.
    function rowCoordinateToPixels(rowCoord) {
      return (daraDotsBoardConstants.boardWidth - daraDotsBoardConstants.boardBuffer) * (rowCoord / 5);
    }

    function colCoordinateToPixels(colCoord) {
      return (daraDotsBoardConstants.boardHeight - daraDotsBoardConstants.boardBuffer) * (colCoord / 5);
    }

    function coordinateToPixels(coords) {
      return [rowCoordinateToPixels(coords[1]), colCoordinateToPixels(coords[0])];
    }
  }
};

export default DaraDotsPhaserWrapper;
