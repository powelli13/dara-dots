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

    // Setup Phaser game
    var config = {
      type: Phaser.AUTO,
      width: 450,
      height: 450,
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
    var testButton;

    function preload () {
      // TODO Phaser examples use game instead of this.
      this.load.image('background', 'game_images/background.jpg');
      this.load.image('star_test', 'game_images/star.png');
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(450, 450, 'background');

      testButton = this.add.image(50, 50, 'star_test')
        .setInteractive()
        .on('pointerdown', () => actionOnClick());

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function actionOnClick () {
      console.log('Sending echo to server');

      gameChannel.push("test_echo", {})
        .receive("error", e => e.console.log(e));
    }
  }
};

export default PhaserWrapper;

