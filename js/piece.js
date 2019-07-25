export default class Piece extends Phaser.GameObjects.Sprite
{
    selected;

    constructor (scene, x, y, texture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);

        this.selected = 'hi there test selected';
    }

    selectPiece()
    {
        this.selected = true;
    }

    deselectPiece()
    {
        this.selected = false;
    }
}