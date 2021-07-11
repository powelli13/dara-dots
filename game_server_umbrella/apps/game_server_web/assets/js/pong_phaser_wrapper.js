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
    ({ballX, ballY, topPaddleX, botPaddleX, topPlayerScore, botPlayerScore}) => {
      moveBallTest(ballX, ballY);

      moveTopPaddle(topPaddleX);

      moveBotPaddle(botPaddleX);

      updateScore(topPlayerScore, botPlayerScore);

      redrawGameObjects();
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
    let graphics;
    let topPaddle;
    let botPaddle;
    let ball;

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      graphics = this.add.graphics({ fillStyle: { color: 0xfefefe } });

      // TODO change these to be based on percentages of the screen width
      topPaddle = new Phaser.Geom.Rectangle(
        0,
        0,
        paddleWidth,
        paddleHeight);
      graphics.fillRectShape(topPaddle);

      botPaddle = new Phaser.Geom.Rectangle(
        0,
        boardHeight * 0.95,
        paddleWidth,
        paddleHeight);
      graphics.fillRectShape(botPaddle);

      ball = new Phaser.Geom.Circle(250, 250, 12.5);
      graphics.fillCircleShape(ball);

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
    }

    function redrawGameObjects() {
        graphics.clear();
        graphics.fillCircleShape(ball);
        graphics.fillRectShape(topPaddle);
        graphics.fillRectShape(botPaddle);
    }

    function moveBallTest(ballX, ballY) {
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

    function updateScore(topPlayerScore, botPlayerScore) {
      let scoreboard = document.getElementById('scoreboard');
      scoreboard.innerHTML = `${topPlayerScore} - ${botPlayerScore}`;
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
