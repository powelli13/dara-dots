import Phaser from "phaser";

let PongPhaserWrapper = {
  init(socket, gameElemId) {
    // Ensure that we only load Pong Phaser on the correct pages
    let gameElement = document.getElementById(gameElemId);
    if (gameElement == null) { return; }

    const params = new URLSearchParams(document.location.search);
    if (!params.has('id')) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, params.get('id'));
  },

  onReady(socket, gameId) {
    let pongGameChannel = socket.channel(`pong_game:${gameId}`, () => {
      return {};
    });

    this.initPhaserGame(pongGameChannel);
  },

  initPhaserGame(gameChannel) {
    // Setup channel listeners
    gameChannel.on("game_state",
    ({ballX, ballY, topPaddleX, botPaddleX, topPlayerScore, botPlayerScore, topPlayerName, botPlayerName}) => {
      moveBall(ballX, ballY);

      moveTopPaddle(topPaddleX);

      moveBotPaddle(botPaddleX);

      updateScore(topPlayerName, topPlayerScore, botPlayerName, botPlayerScore);

      redrawGameObjects();
    });

    gameChannel.on("game_over",
    ({winnerName}) => {
      updateWinner(winnerName);
    });

    gameChannel.on("player_status",
    ({position}) => {
      populateGameInstructions(position);
    });

    gameChannel.join()
      .receive("ok", (resp) => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));

    // Setup display dimension
    const boardWidth = 500;
    const boardHeight = 500;

    // Paddle width is ten percent of the board width
    // Paddle height is five percent of the board height 
    const paddleWidth = boardWidth * 0.1;
    const paddleHeight = boardHeight * 0.05;

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

    // Setup game objects
    let whiteGraphics;
    let grayGraphics;
    let blueGraphics;
    let redGraphics;
    
    // Sprites and bools to allow for moving by clicking the arrows
    let leftMoveClick;
    let rightMoveClick;
    let movingLeft = false;
    let movingRight = false;
    
    let topPaddle;
    let botPaddle;
    let ball;

    function preload () {
      this.load.image("background", "game_images/background.jpg");
      this.load.image("left_move_arrow", "game_images/left_move_arrow.png");
      this.load.image("right_move_arrow", "game_images/right_move_arrow.png");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      whiteGraphics = this.add.graphics({ fillStyle: { color: 0xfefefe } });
      grayGraphics = this.add.graphics({ fillStyle: { color: 0xd3d3d3, alpha: 0.5 } });
      blueGraphics = this.add.graphics({ fillStyle: { color: 0x1a8dff } });
      redGraphics = this.add.graphics({ fillStyle: { color: 0xff1a1a } });

      topPaddle = new Phaser.Geom.Rectangle(
        0,
        0,
        paddleWidth,
        paddleHeight);
      blueGraphics.fillRectShape(topPaddle);

      botPaddle = new Phaser.Geom.Rectangle(
        0,
        boardHeight * 0.95,
        paddleWidth,
        paddleHeight);
      redGraphics.fillRectShape(botPaddle);

      ball = new Phaser.Geom.Circle(250, 250, 12.5);
      whiteGraphics.fillCircleShape(ball);

      // Initialize the clickers used to move the ball, needed for mobile play
      leftMoveClick = this.add.sprite(35, boardHeight / 2, "left_move_arrow").setInteractive();
      leftMoveClick.alpha = 0.35;
      leftMoveClick.on("pointerdown", function (pointer) {
        movingLeft = true;
      });
      leftMoveClick.on("pointerup", function (pointer) {
        movingLeft = false;
      });
      leftMoveClick.on("pointerout", function (pointer) {
        movingLeft = false;
      });

      rightMoveClick = this.add.sprite(465, boardHeight / 2, "right_move_arrow").setInteractive();
      rightMoveClick.alpha = 0.35;
      rightMoveClick.on("pointerdown", function (pointer) {
        movingRight = true;
      });
      rightMoveClick.on("pointerup", function (pointer) {
        movingRight = false
      });
      rightMoveClick.on("pointerout", function (pointer) {
        movingRight = false;
      });

      // Bind the arrow keys to moving the rectangle
      this.input.keyboard.on('keydown-LEFT', function (event) {
        gameChannel.push("move_paddle_left", {})
          .receive("error", e => e.console.log(e));
      });

      this.input.keyboard.on('keydown-RIGHT', function (event) {
        gameChannel.push("move_paddle_right", {})
          .receive("error", e => e.console.log(e));
      });

      this.input.mouse.disableContextMenu();
    }

    function update () {
      if (movingLeft)
      {
        gameChannel.push("move_paddle_left", {})
          .receive("error", e => e.console.log(e));
      }

      if (movingRight)
      {
        gameChannel.push("move_paddle_right", {})
          .receive("error", e => e.console.log(e));
      }
    }

    function redrawGameObjects() {
      whiteGraphics.clear();
      blueGraphics.clear();
      redGraphics.clear();

      whiteGraphics.fillCircleShape(ball);
      blueGraphics.fillRectShape(topPaddle);
      redGraphics.fillRectShape(botPaddle);
    }

    function moveBall(ballX, ballY) {
      if (ball != null) {
        ball.x = percentWidthToPixels(ballX);

        // Ball position comes as a percentage
        // flip this because lower Y value is closer
        // to the top of the screen in the framework.
        ball.y = percentHeightToPixels(ballY);
      }
    }

    function moveTopPaddle(topPaddleX) {
      topPaddle.x = percentWidthToPixels(topPaddleX);
    }

    function moveBotPaddle(botPaddleX) {
      botPaddle.x = percentWidthToPixels(botPaddleX);
    }

    function updateScore(topPlayerName, topPlayerScore, botPlayerName, botPlayerScore) {
      let scoreboard = document.getElementById('scoreboard');
      scoreboard.innerHTML = `${topPlayerName}: ${topPlayerScore} - ${botPlayerName}: ${botPlayerScore}`;
    }

    function updateWinner(winnerName) {
      let announcement = document.getElementById('announcement');
      announcement.innerHTML = `Game over! The winner is ${winnerName}.`;
    }

    function populateGameInstructions(position) {
      const color = position == 'top' ? 'blue' : 'red';
      let instructions = document.getElementById('instructions');
      instructions.innerHTML =
        `You play on ${position} as the ${color} paddle. Use the arrow keys to move.`;
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

export default PongPhaserWrapper;
