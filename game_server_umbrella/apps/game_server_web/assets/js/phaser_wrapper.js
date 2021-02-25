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

    // Only load the Phaser assets on certain pages
    var config = {
        type: Phaser.AUTO,
        width: 800,
        height: 700,
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
    }

    function create ()
    {
        // Only load the Phaser assets on certain pages
        this.add.image(400, 300, 'background');

        this.input.mouse.disableContextMenu();
    }

    function update ()
    {
    }
  }
};

export default PhaserWrapper;

