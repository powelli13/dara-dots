
# dara-dots
Using Phaser 3 to implement a game idea I have.

Below is an evolving description of the game and rules:
This is mainly a brain dump right now. Better formatting
and reading structure will be worked on later.

The Board:
The game is played on a board that contains nodes and links. 
The nodes are arranged in a five by five square formation
with equal spacing between nodes. Each node has links connecting
it to the other nodes. The space in between links is a square.
The five nodes closest to each player is their Home Row.
All pieces reside on nodes and move along links except
the circle which resides in squares and moves across links.
A node is open when no pieces are currently placed on it.
A square is open when no pieces are currently in it.

Start:
The game begins with all pieces off the board. A coin
is flipped (or equivalent 50/50 randomization) to decide
which player goes first. A player may use two action points
to place a piece (see below). If the player's star piece
is on the board then they may place a piece by spending 
just one action point. Pieces are placed on the nodes and 
squares nearest to the home row.

Endgame:
If a player moves their star piece onto the home row of their
opponent they win.
A player may also win if they capture the opposing players star
piece 3 times.

TODO possibly need another win condition or a way to ensure
that players don't stall and never put out their star.

The Actions:
Each turn a player has four action points.

A single action point may be used for the following:
    - Move a piece
    - Move the triangle or star onto the block and off
    - Move to capture
    - Place a piece onto their home row.
        Costs two action points if the star is on 
        the board, otherwise one.

When a piece is captured it is removed from the board.
The piece may be placed back onto the board during
the player's next turn should they decide to use
their action points for that.

The Pieces:

Star:
The star resides on nodes and moves along links.
When the star is on the board placing a friendly
piece only costs 1 action point.
The star may land on the opposing circle's disc
capturing it and removing the disc also.
When the star reaches the opposing side's home row 
the star's team wins.
If the star is captured three times the opposing team
wins.

Triangle:
The triangle resides on nodes and moves along links.
The triangle may move onto the opposing star capturing
it.
The triangle may move onto the square and off onto
an empty node or the opposing star.

Block:
The block resides on nodes and moves along links.
The triangle and star of the same team may move onto
the block and then off in any direction given that it
is a legal move.

Circle:
The circle resides in squares and moves over links.
Upon moving the circle may place its disc on any
node surrounding the square that it is in.
The placed disc may be placed on an opposing block
to capture it.
The opposing triangle and block may not move through
the disc.
