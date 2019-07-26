export default class Piece extends Phaser.GameObjects.Sprite
{
    Selected;
    Texture;
    AltTexture;

    constructor (scene, x, y, texture, altTexture)
    {
        super(scene, x, y);

        this.Texture = texture;
        this.AltTexture = altTexture;

        this.setTexture(texture);
        this.setPosition(x, y);

        this.Selected = false;
    }

    selectPiece()
    {
        this.Selected = true;
        this.setTexture(this.AltTexture);
    }

    deselectPiece()
    {
        this.Selected = false;
        this.setTexture(this.Texture);
    }
}