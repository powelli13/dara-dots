export default class boardNode extends Phaser.GameObjects.Sprite
{
    boardX;
    boardY;

    constructor(scene, x, y, boardXIndex, boardYIndex, texture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);

        this.boardX = boardXIndex;
        this.boardY = boardYIndex;
    }

    
}