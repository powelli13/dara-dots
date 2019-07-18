import Piece from "./piece";

export default class StarPiece extends Piece {

    // selected = false;

    constructor (scene, x, y, texture)
    {
        super(scene, x, y, texture);

        // this.setTexture(texture);
        this.setPosition(x, y);
    }

    preUpdate (time, delta)
    {
        super.preUpdate(time, delta);
    }

    // selectPiece()
    // {
    //     super.selectPiece();
    // }

    // TODO add mouse click reactivity

    // pointerDown (pointer)
    // {

    // }
}
