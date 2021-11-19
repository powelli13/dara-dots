# Dara Dots
Dara Dots is a turn based one versus one competitive game.

## Objective
The objective of Dara Dots is to score five points against your opponent. Points are scored when a Runner piece advances past the home row of your opponents side of the board.

## Board
The board consists of a five by five grid of dots. Both Linker and Runner pieces can be positioned on these dots.
The dots are arranged in five columns of five dots each. The top and bottom rows of dots on the board are the home rows of the respective players. The player controlled Linker pieces start in the home row and the home row is also how points are scored.

## Pieces
Dara Dots consists of two types of pieces. Linkers, which are controller by the players, and Runners which are neutral pieces that move automatically at the end of each turn.

### Runner
Runners are the neutral pieces that players manipulate in order to score goals. The Runners move straight up or down a column. Runners have set speeds of one, two, three, four or five and at the end of each player's turn a Runner advances one dot per their speed.
Runner pieces are represented by Triangles, with the single point facing in their direction of movement.

#### Changing Columns
Linkers can create links between columns. Links can be used to change the column and direction of a Runner.

#### Scoring
If a Runner is in the home row of a player then their opponent scores one point.

#### Runner Collision
Option 1.
Runners are placed in a queue with priority based on when they entered the board. At the end of each turn the Runner pieces advance up or down the column with the number of dots oved being equal to their speed.
If a Runner collides with a Runner moving in the opposite direction, then the Runner that was placed earlier on the board is preserved and the other Runner is removed from the board.

Option 2.
Runners simply pass through each other and do not slow down or destroy one another. 

### Linkers
Each player has two Linker pieces. The Linkers move orthogonally one dot at a time. When a Linker moves across columns it creates a link between the columns. If a Runner moving up or down a certain column encounters a link then they will move to the other column, change directions and increase their speed.
Linker pieces are represented by a Square.

#### Linker Collision
Linkers cannot move on to a square that is occupied by another Linker, whether on the same team or not.
*TODO idea here to allow hoping over the Linker that is on the same team, I think that it could make for some more interesting movement*

## Turn Order
On a player's turn they have three actions. An action can either move one of the player's Linker pieces or place a Runner on a dot moving toward their opponents home row.

Once the player has entered their three actions then all Runners automatically move.

## Starting Positions
The player's Linker pieces are positioned randomly in their home row. Also one Runner piece is positioned in a random column on their home row moving toward the opponent. Whichever player goes second has their Runner start in the second row up.
*Example Image*

## Endgame
The game ends when a player has scored five points against their opponent.
