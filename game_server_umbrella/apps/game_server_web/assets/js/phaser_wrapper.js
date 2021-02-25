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
    var masterGroup;

    function preload ()
    {
      this.load.image('background', 'game_images/background.jpg');
      this.load.image('star_test', 'game_images/star.png');
    }

    function create ()
    {
      // Only load the Phaser assets on certain pages
      this.add.image(450, 450, 'background');
      this.add.image(25, 25, 'star_test');

      this.input.mouse.disableContextMenu();
    }

    function update ()
    {
      console.log('hi there updating from Phaser');
    }
  }
};

export default PhaserWrapper;

