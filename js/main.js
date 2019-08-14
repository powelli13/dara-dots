import StarPiece from './starpiece.js';
import BoardNode from './boardNode.js';

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
var board;

const boardSpacing = 100;
const dotDepth = 5;
const pieceDepth = 10;

// Blue moves first
const blueTeam = 0;
const redTeam = 1;
var turn = blueTeam;

// var dotGroup;
var selectedPiece = null;

/*
TODO list
- research best practices for sprites or game object
    I imagine that there is a better way than images for everything
    look for sprite class or some game object I could extend (see flood-fill.js example)
- see if extending a scene makes sense for this game or for menus (see flood-fill.js example)
- find best built in way for mouse click detection and have piece classes interact well with that
    ideally there will be some global handler for these to click and move the pieces
    rather than adhoc position changes for each individual piece


Notes
Some design considerations:
should the representation of the game state be independent of
the sprite objects?
    - this would mean have one object to hold all the game state
    and when it is told to animate
    it places the sprites where they should go
another route is having pieces and or board nodes as objects which
have their own methods to move themselves and change their state.

important events in game play to keep in mind:
    - click piece once it is themn selected, click on another square it will attempt to move
    - 
*/

function preload ()
{
    this.load.image('background', 'assets/images/background.jpg');
    this.load.image('dot', 'assets/images/dot.png');
    this.load.image('boardDot', 'assets/images/board_dot.png');
    this.load.image('altBoardDot', 'assets/images/alt_board_dot.png');
    this.load.image('offBoardDot', 'assets/images/offboard_dot.png');
    this.load.image('star', 'assets/images/star.png');
    this.load.image('altStar', 'assets/images/alt_star.png');

}

function create ()
{
    this.add.image(400, 300, 'background');

    // TODO make it so that pieces render on top of nodes
    masterGroup = this.add.group();
    // TODO use two data structures
    // one to lookup all nodes quickly
    // the other to record structure
    boardNodes = {};
    boardGraph = {};

    
    // TODO how to reference a sprite later once it is added to the game sprites
    let starPieceSprite = new StarPiece(this, 50, 50, 'star', 'altStar', blueTeam, 'star').setInteractive();
    // starPieceSprite.z = pieceDepth;
    starPieceSprite.on('pointerdown', function (pointer)
    {
        if (selectedPiece == null)
        {
            this.selectPiece();
            selectedPiece = this;
        }
    });

    masterGroup.add(starPieceSprite);

    this.add.existing(starPieceSprite);

    // Setup the board
    // 0,0 is top left node
    let newId = 0;
    for (let row = 0; row < 5; row++)
    {
        // something like this will be helpful when making the graph
        // this is possible in js, not sure if it is best though
        // the board should be created by some json file
        // probably just use standard spacing for now or something
        if (boardNodes[newId] === undefined)
        {
            boardNodes[newId] = [];
        }
        else
        {
            boardNodes[newId][boardNodes[newId].length] = newId;
        }

        for (let col = 0; col < 5; col++)
        {

            let boardDotSprite = new BoardNode(this, 
                (col + 1) * boardSpacing, 
                (row + 1) * boardSpacing,
                'boardDot',
                'altBoardDot',
                newId++).setInteractive();
                // TODO fill in graph 
            this.add.existing(boardDotSprite);
            board[row][col] = boardDotSprite;

            // boardDotImage.z = dotDepth;
            boardDotSprite.on('pointerdown', function (pointer)
            {
                // TODO add more logic around this to check for a not null selected piece?
                if (selectedPiece != null)
                {
                    selectedPiece.Move(this.x, this.y, this.Id);
                    console.info(this.Id);

                    // TODO ensure the piece can move here 
                    /* thoughts on an algorithm for checking legal moves:
                    is spot open
                    is friendly block
                    are we triangle is opposing star
                    are we star is opposing circle's disc

                    */
                    // if (turn == selectedPiece.Team)
                    // {

                    // }

                    // TODO left off 
                    // having conceptual trouble deciding if this should be
                    // piece or node centric
                    // the fact that sprite objects are being used
                    // rather than a single board object makes this tricky
                    // i need to plan this out more before finalizing movement logic
                    // moving:
                    // piece gets selected
                    // need to know:
                    // - whose turn
                    // - type of piece
                    // - which node piece is on
                    // - which nodes are linked to current node
                    // - types of pieces occupying those nodes
                    
                    // idea:
                    // have a multi directional graph of nodes in main
                    // dynamically animate links based on the graph
                    // give every node an id
                    // when a piece is selected get the id of the 
                    // node that it occupies
                    // lookup other linked nodes in the graph
                    // problem with this is that if only the piece
                    // is aware of the node-piece connection then
                    // all pieces will have to be scanned to find 
                    // out of adjacent nodes are occupied and by what
                    // i think setting a piece link on the node is fine

                    // TODO circle movement
                    // crossing a link will need to be measurable
                    // the spaces between links could be treated
                    // as their own kind of square
                    // question to address later is do their area and 
                    // edge links change if/when links between nodes are destroyed/created
                    
                    // in order to make the game flexible with respect to different
                    // board node orientations in the future movement will 
                    // depend entirely on the links connecting
                    // the nodes rather than a static board structure
                    // this allows for future design to play on different
                    // node-link setusps and for node-link
                    // structure to change dynamically during the game.
                    selectedPiece.deselectPiece();
                    selectedPiece = null;
                }
            });
            // boardDotSprite.setAlpha(1);
            // masterGroup.add(boardDotSprite);
        }
    }
    
    // Setup offboard positions
    let greenDot = this.add.sprite(6 * boardSpacing, 4 * boardSpacing, 'offBoardDot').setInteractive();
    greenDot.z = dotDepth;
    masterGroup.add(greenDot);

    starPieceSprite.x = 6 * boardSpacing;
    starPieceSprite.y = 4 * boardSpacing;

    this.input.mouse.disableContextMenu();
}

function update ()
{

}