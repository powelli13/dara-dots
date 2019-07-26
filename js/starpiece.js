import Piece from "./piece";

export default class StarPiece extends Piece {

    constructor (scene, x, y, texture, altTexture)
    {
        super(scene, x, y, texture, altTexture);

        this.setTexture(texture);
        this.setPosition(x, y);
    }

    preUpdate (time, delta)
    {
        super.preUpdate(time, delta);

    }

    // TODO movement differs from pieces but two different textures and selection does not

    // selectPiece()
    // {
    //     super.selectPiece();

    //     // TODO find best way to do this within phaser
        
    //     this.setTexture(altTexture);
    // }

    // deselectPiece()
    // {
    //     super.deselectPiece();

    //     this.setTexture(texture);
    // }

    // // TODO add mouse click reactivity

    // // pointerDown (pointer)
    // // {

    // // }
}
