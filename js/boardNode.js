export default class BoardNode extends Phaser.GameObjects.Sprite
{
    BoardX;
    BoardY;

    Texture;
    AltTexture;

    constructor(scene, x, y, boardXIndex, boardYIndex, texture, altTexture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);

        this.BoardX = boardXIndex;
        this.BoardY = boardYIndex;

        this.Texture = texture;
        this.AltTexture = altTexture;
    }

    preUpdate (time, delta)
    {
        super.preUpdate(time, delta);

    }

    selectNode()
    {
        this.setTexture(this.AltTexture);
    }
    
    deselectNode()
    {
        this.setTexture(this.Texture);
    }
}