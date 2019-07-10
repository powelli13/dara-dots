export default class StarPiece extends Phaser.GameObjects.Sprite {

    constructor (scene, x, y, texture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);
    }

    preUpdate (time, delta)
    {
        super.preUpdate(time, delta);

        this.rotation += 0.01;
    }

    // TODO add mouse click reactivity
}
