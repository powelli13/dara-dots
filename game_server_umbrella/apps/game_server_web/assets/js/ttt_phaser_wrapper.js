import Phaser from "phaser";

let TttPhaserWrapper = {
  init(socket, urlParam) {
    let params = new URLSearchParams(document.location.search);
    // TODO this causes TTT board to show on the RPS screen as well
    // need to have a better differentiation
    if (!params.has(urlParam)) { return; }

    socket.connect();

    this.onReady(socket, params.get(urlParam));
  },

  onReady(socket, gameId) {
    console.log("Tic Tac Toe Phaser wrapper is now ready");

    var ticTacToeGameChannel = socket.channel("ttt_game:" + gameId, () => {
      let username = window.localStorage.getItem("player_name");
      return {username: username};
    });

    this.initPhaserGame(ticTacToeGameChannel)
  },

  initPhaserGame(gameChannel) {
    // TODO restructure this for readability
    // Setup channel listeners
    gameChannel.on("new_board_state", ({board}) => {
      updateBoardState(board);
    });

    gameChannel.on("game_winner", (resp) => {
      winningIndices = resp.indices;
      postGameAlert(`Game over! Winner is ${resp.name} playing ${resp.piece}`);
    });

    gameChannel.on("game_drawn", (resp) => {
      postGameAlert('Game drawn! Thanks for playing');
    });

    gameChannel.join()
      .receive("ok", () => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));

    // Display constants
    const boardWidth = 450;
    const boardHeight = 450;
    const bufferSize = 25;

    // Piece sizes and locations
    const circleRadius = (boardWidth/6) - bufferSize;
    const crossLength = boardWidth/6;

    // Indexes displayed below
    // 0 | 1 | 2
    // 3 | 4 | 5
    // 6 | 7 | 8
    // Subarrays is X, Y
    // Center and padding consts
    // TODO can I move the const stuff to a separate file?
    const cX = boardWidth/2;
    const cY = boardHeight/2;
    const pX = boardWidth/3;
    const pY = boardHeight/3;
    const squareCenterLocations = [
      [cX-pX, cY-pY], [cX, cY-pY], [cX+pX, cY-pY],
      [cX-pX, cY], [cX, cY], [cX+pX, cY],
      [cX-pX, cY+pY], [cX, cY+pY], [cX+pX, cY+pY]
    ];

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
    var graphics;
    var redGraphics;
    var boardLines = [];
    var boardState = [];
    var victoryLines = {};
    var winningIndices = [];
    var circlePiece;
    var crossPiece = [];

    function preload () {
      // TODO Phaser examples use game instead of 'this', does it matter?
      this.load.image("background", "game_images/background.jpg");
      this.load.image("star", "game_images/star.png");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      // Setup the board as an array of lines
      graphics = this.add.graphics({ lineStyle: { width: 4, color: 0xfefefe } });
      redGraphics = this.add.graphics({ lineStyle: { width: 6, color: 0xfe4422 } });

      boardLines.push(new Phaser.Geom.Line(
        boardWidth/3, bufferSize,
        boardWidth/3, boardHeight - bufferSize));
      boardLines.push(new Phaser.Geom.Line(
        2*(boardWidth/3), bufferSize,
        2*(boardWidth/3), boardHeight-bufferSize));
      boardLines.push(new Phaser.Geom.Line(
        bufferSize, boardHeight/3,
        boardWidth-bufferSize, boardHeight/3));
      boardLines.push(new Phaser.Geom.Line(
        bufferSize, 2*(boardHeight/3),
        boardWidth-bufferSize, 2*(boardHeight/3)));

      circlePiece = new Phaser.Geom.Circle(0, 0, circleRadius);
      crossPiece.push(new Phaser.Geom.Line(0, 0, crossLength, crossLength));
      crossPiece.push(new Phaser.Geom.Line(0, crossLength, crossLength, 0));

      // Prepare lines to display the victory path that was used on game over
      // TODO this may be overkill, why not just draw the line based on to from indices as needed?
      const possibleVictorySquareIndices = [
        [0, 2],
        [0, 6],
        [0, 8],
        [1, 7],
        [2, 6],
        [2, 8],
        [3, 5],
        [6, 8]
      ];

      possibleVictorySquareIndices.forEach((indexPair, i) => {
        victoryLines[indexPair] = new Phaser.Geom.Line(
          squareCenterLocations[indexPair[0]][0], squareCenterLocations[indexPair[0]][1],
          squareCenterLocations[indexPair[1]][0], squareCenterLocations[indexPair[1]][1]
        );
      });

      // Setup sprites for clicking spaces
      squareCenterLocations.forEach((xy, i) => {
        // TODO star isn't necessary here, another image could be used
        // TODO looks like 0.0 alpha prevents clicks from interacting
        let spriteStar = this.add.sprite(xy[0], xy[1], "star").setInteractive();
        spriteStar.alpha = 0.15;
        spriteStar.on("pointerup", function (pointer) {
          gameChannel.push("submit_move", {"move_index": i})
            .receive("error", e => e.console.log(e));
        });
      });

      this.input.mouse.disableContextMenu();
    }

    function update () {
      graphics.clear();
      redGraphics.clear();

      boardLines.forEach((v, i) => { graphics.strokeLineShape(v); });

      drawBoardState();
    }

    function drawBoardState () {
      squareCenterLocations.forEach((xy, i) => {
        if (boardState[i] == "X") {
          crossPiece.forEach((line, il) => {
            Phaser.Geom.Line.CenterOn(line, xy[0], xy[1]);
            graphics.strokeLineShape(line);
          });
        } else if (boardState[i] == "O") {
          circlePiece.x = xy[0];
          circlePiece.y = xy[1];
          graphics.strokeCircleShape(circlePiece);
        }
      });

      // If winningIndices is populated then it represents a winning line
      if (winningIndices.length == 2) {
        redGraphics.strokeLineShape(victoryLines[winningIndices]);
      }
    }

    function updateBoardState (newBoardState) {
      boardState = newBoardState;
    }

    function postGameAlert (alert) {
      let alertsElement = document.getElementById("game-alerts");
      alertsElement.innerHTML = alert;
    }
  }
};

export default TttPhaserWrapper;
