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
    gameChannel.on("move_ball", ({ballX, ballY}) => {
      moveBallTest(ballX, ballY);
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
        console.log('left arrow down');
        console.log(rect.x);
        if (rect.x > 0) {
          rect.x -= 1;

          graphics.clear();
          graphics.fillRectShape(rect);
          graphics.fillCircleShape(ball);
        }
      });

      this.input.keyboard.on('keydown-RIGHT', function (event) {
        console.log('right arrow down');
        console.log(rect.x);
        if (rect.x < 500) {
          rect.x += 1;

          graphics.clear();
          graphics.fillRectShape(rect);
          graphics.fillCircleShape(ball);
        }
      });

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function moveBallTest(ballX, ballY) {
      if (ball != null) {
        ball.x = ballX;
        ball.y = ballY;

        graphics.clear();
        graphics.fillCircleShape(ball);
        graphics.fillRectShape(rect);
      }
    }
  }
};

export default PongPhaserWrapper;
