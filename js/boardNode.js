export default class BoardNode extends Phaser.GameObjects.Sprite
{
    Texture;
    AltTexture;

    constructor(scene, x, y, texture, altTexture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);

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