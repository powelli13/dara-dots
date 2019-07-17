export default class StarPiece extends Phaser.GameObjects.Sprite {

    // selected = false;

    constructor (scene, x, y, texture)
    {
        super(scene, x, y);

        this.setTexture(texture);
        this.setPosition(x, y);
    }

    preUpdate (time, delta)
    {
        super.preUpdate(time, delta);
    }



    // TODO add mouse click reactivity

    // pointerDown (pointer)
    // {

    // }
}
