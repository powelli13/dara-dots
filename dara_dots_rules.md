# Dara Dots
Dara Dots is a turn based one versus one competitive game.

## Objective
The objective of Dara Dots is to score five points against your opponent. Points are scored when a Triangle piece advances past the home row of your opponents side of the board.

## Board
The board consists of a five by five grid of dots. Both Square and Triangle pieces can be positioned on these dots.
The dots are arranged in five columns of five dots each. The top and bottom rows of dots on the board are the home rows of the respective players. The player controlled Square pieces start in the home row and the home row is also how points are scored.

## Pieces
Dara Dots consists of two types of pieces. Squares, which are controller by the players, and Triangles which are neutral pieces that move automatically at the end of each turn.

### Triangle
Triangles are the neutral pieces that players manipulate in order to score goals. The Triangles move straight up or down a column. Triangles have set speeds of one, two, three, four or five and at the end of each player's turn a Triangle advances one dot per their speed.

#### Changing Columns
Squares can create links between columns. Links can be used to change the column and direction of a Triangle.

#### Scoring
If a Triangle is in the home row of a player then their opponent scores one point.

#### Triangle Collision
TODO

### Squares
Each player has two Square pieces. The Squares move orthogonally one dot at a time. When a Square moves across columns it creates a link between the columns. If a Triangle moving up or down a certain column encounters a link then they will move to the other column, change directions and increase their speed.

#### Square Collision
TODO

## Turn Order
On a player's turn they have three actions. An action can either move one of the player's Square pieces or place a Triangle on a dot moving toward their opponents home row.

Once the player has entered their three actions then all Triangles automatically move.

## Starting Positions
The player's Square pieces are positioned randomly in their home row. Also one Triangle piece is positioned in a random column on their home row moving toward the opponent. Whichever player goes second has their Triangle start in the second row up.
*Example Image*

## Endgame
The game ends when a player has scored five points against their opponent.
