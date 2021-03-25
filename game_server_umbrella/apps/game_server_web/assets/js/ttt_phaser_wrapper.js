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
      let username = window.localStorage.getItem("dara-username");
      return username 
        ? {username: username}
        : {username: "anon" + Math.floor(Math.random() * 1000)};
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
      console.log("game winner:");
      console.log(resp);
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
    var boardLines = [];
    var boardState = [];
    var circlePiece;
    var crossPiece = [];

    function preload () {
      // TODO Phaser examples use game instead of this.
      this.load.image("background", "game_images/background.jpg");
      this.load.image("star", "game_images/star.png");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      // Setup the board as an array of lines
      graphics = this.add.graphics({ lineStyle: { width: 4, color: 0xfefefe } });

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
    }

    function updateBoardState (newBoardState) {
      boardState = newBoardState;
    }
  }
};

export default TttPhaserWrapper;