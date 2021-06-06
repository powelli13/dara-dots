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
    var pongGameChannel = socket.channel("pong_game:1", () => {
      return {};
    });

    this.initPhaserGame(pongGameChannel);
  },

  initPhaserGame(gameChannel) {
    // Setup channel listeners
    gameChannel.on("game_state", ({ballX, ballY, botPaddleX}) => {
      moveBallTest(ballX, ballY);

      moveBotPaddle(botPaddleX);

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

    // Setup game objects
    var graphics;
    var rect;
    var ball;

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      graphics = this.add.graphics({ fillStyle: { color: 0xfefefe } });

      rect = new Phaser.Geom.Rectangle(20, 400, 50, 25);
      graphics.fillRectShape(rect);

      ball = new Phaser.Geom.Circle(250, 250, 25);
      graphics.fillCircleShape(ball);

      // Bind the arrow keys to moving the rectangle
      this.input.keyboard.on('keydown-LEFT', function (event) {
        if (rect.x > 0) {
          gameChannel.push("move_paddle_left", {})
            .receive("error", e => e.console.log(e));
        }
      });

      this.input.keyboard.on('keydown-RIGHT', function (event) {
        if (rect.x < 500) {
          gameChannel.push("move_paddle_right", {})
            .receive("error", e => e.console.log(e));
        }
      });

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function redrawGameObjects() {
        graphics.clear();
        graphics.fillCircleShape(ball);
        graphics.fillRectShape(rect);
    }

    function moveBallTest(ballX, ballY) {
      if (ball != null) {
        ball.x = percentWidthToPixels(ballX);
        ball.y = percentHeightToPixels(ballY);
      }
    }

    function moveBotPaddle(botPaddleX) {
      rect.x = percentWidthToPixels(botPaddleX);
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
