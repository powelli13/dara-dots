var config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
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
var dotGroup;

function preload ()
{
    this.load.image('background', 'assets/images/background.jpg');
    this.load.image('dot', 'assets/images/dot.png');
}

function create ()
{
    this.add.image(400, 300, 'background');
    var dotImage = this.add.image(0, 0, 'dot');
    
    dotGroup = this.add.group();
    dotGroup.add(dotImage);

    this.input.mouse.disableContextMenu();

    this.input.on('pointerup', function(p){
        if (p.leftButtonReleased())
        {
            console.info('left pressed at ' + p.worldX + ' '+ p.worldY);
            Phaser.Actions.SetXY(dotGroup.getChildren(), p.worldX, p.worldY);
        }
    });
}

function update ()
{
    // var pointer = this.input.activePointer;

    // if (pointer.leftButtonReleased())
    // {
    //     // this.add.image(pointer.worldX, pointer.worldY, 'dot');
    //     Phaser.Actions.SetXY(dotGroup.getChildren(), pointer.worldX, pointer.worldY);
    // }
}