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
    this.initPhaserGame();
  },

  initPhaserGame() {
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

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      graphics = this.add.graphics({ fillStyle: { color: 0xfefefe } });

      rect = new Phaser.Geom.Rectangle(20, 400, 50, 25);
      graphics.fillRectShape(rect);

      // Bind the arrow keys to moving the rectangle
      this.input.keyboard.on('keydown-LEFT', function (event) {
        console.log('left arrow down');
        console.log(rect.x);
        if (rect.x > 0) {
          rect.x -= 1;

          graphics.clear();
          graphics.fillRectShape(rect);
        }
      });

      this.input.keyboard.on('keydown-RIGHT', function (event) {
        console.log('right arrow down');
        console.log(rect.x);
        if (rect.x < 500) {
          rect.x += 1;

          graphics.clear();
          graphics.fillRectShape(rect);
        }
      });

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }
  }
};

export default PongPhaserWrapper;
