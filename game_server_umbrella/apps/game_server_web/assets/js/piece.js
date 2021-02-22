export default class Piece extends Phaser.GameObjects.Sprite
{
    Team;
    Type;
    NodeId;
    Selected;
    Texture;
    AltTexture;

    constructor (scene, x, y, texture, altTexture, team, type)
    {
        super(scene, x, y);

        this.Texture = texture;
        this.AltTexture = altTexture;

        this.setTexture(texture);
        this.setPosition(x, y);

        this.Selected = false;
        this.Team = team;
        this.Type = type;
    }

    Move(x, y, nodeId)
    {
        this.x = x;
        this.y = y;
        this.NodeId = nodeId;
        // TODO move off of board
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