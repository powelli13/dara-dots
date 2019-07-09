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
var boardDotGroup;
// var boardXSpacing = 100;
var boardSpacing = 100;

var dotGroup;

function preload ()
{
    this.load.image('background', 'assets/images/background.jpg');
    this.load.image('dot', 'assets/images/dot.png');
    this.load.image('boardDot', 'assets/images/board_dot.png');
}

function create ()
{
    this.add.image(400, 300, 'background');
    var dotImage = this.add.image(0, 0, 'dot');
    
    dotGroup = this.add.group();
    dotGroup.add(dotImage);

    // Setup the board
    boardDotGroup = this.add.group();

    for (let x = 0; x < 5; x++)
    {
        for (let y = 0; y < 5; y++)
        {
            let boardDotImage = this.add.image((x+1) * boardSpacing, (y+1) * boardSpacing, 'boardDot');
            boardDotImage.setAlpha(1);
            boardDotGroup.add(boardDotImage);
        }
    }
     
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