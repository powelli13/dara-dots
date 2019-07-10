import StarPiece from './starpiece.js';

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

/*
TODO list
- research best practices for sprites or game object
    I imagine that there is a better way than images for everything
    look for sprite class or some game object I could extend (see flood-fill.js example)
- see if extending a scene makes sense for this game or for menus (see flood-fill.js example)
- find best built in way for mouse click detection and have piece classes interact well with that
    ideally there will be some global handler for these to click and move the pieces
    rather than adhoc position changes for each individual piece
*/

function preload ()
{
    this.load.image('background', 'assets/images/background.jpg');
    this.load.image('dot', 'assets/images/dot.png');
    this.load.image('boardDot', 'assets/images/board_dot.png');
    this.load.image('star', 'assets/images/star.png');
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
     
    this.add.existing(new StarPiece(this, 50, 50, 'star'));

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