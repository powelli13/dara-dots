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

    this.initPhaserGame(socket)
  },

  initPhaserGame(socket) {
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
      console.log('clicked the button');
    }
  }
};

export default PhaserWrapper;

