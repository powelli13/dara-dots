import Phaser from 'phaser';

let PhaserWrapper = {
  init(socket, element) {
    if (!element) {
      return;
    }

    socket.connect();

    this.onReady(socket);
  },

  onReady(socket) {
    console.log('Phaser wrapper is now ready');

    var ticTacToeGameChannel = socket.channel('ttt_game:1', () => {
      return {};
    });

    this.initPhaserGame(ticTacToeGameChannel)
  },

  initPhaserGame(gameChannel) {
    // TODO restructure this for readability
    // Setup channel listeners
    gameChannel.on("test_echo", (resp) => {
      console.log("echo from server");
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

    // Setup Phaser game
    var config = {
      type: Phaser.AUTO,
      width: boardWidth,
      height: boardHeight,
      physics: {
        default: 'arcade',
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
    var testButton;
    var boardLines = [];
    var boardState = [];

    function preload () {
      // TODO Phaser examples use game instead of this.
      this.load.image('background', 'game_images/background.jpg');
      this.load.image('star_test', 'game_images/star.png');
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, 'background');

      testButton = this.add.image(50, 50, 'star_test')
        .setInteractive()
        .on('pointerdown', () => actionOnClick());

      // Setup the board as an array of lines
      graphics = this.add.graphics({ lineStyle: { width: 4, color: 0xfefefe } });
      // TODO some algebra when building the board
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

      this.input.mouse.disableContextMenu();
    }

    function update () {
      graphics.clear();

      boardLines.forEach((v, i) => { graphics.strokeLineShape(v); });
    }

    function drawBoardState () {

    }

    function actionOnClick () {
      console.log('Sending echo to server');

      gameChannel.push("test_echo", {})
        .receive("error", e => e.console.log(e));
    }
  }
};

export default PhaserWrapper;
