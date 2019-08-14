export default class BoardNode extends Phaser.GameObjects.Sprite
{
    Id;
    Texture;
    AltTexture;

    constructor(scene, x, y, texture, altTexture, id)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);

        this.Texture = texture;
        this.AltTexture = altTexture;
        this.Id = id;
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