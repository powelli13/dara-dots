# Dara Dots
Dara Dots is a multiplayer cooperative puzzle game.

## Objective
The objective of Dara Dots is for the players to stamp every dot on the board at least once while at the same time moving their stamp from the respective starting location to the ending location.

## Board
The board consists of many dots. The structure, orientation and sparcity of the dots will vary. This means that each board will comprise of a distinct puzzle with different solutions.

### Neutral Dots
The neutral dots on the boardsimpl are dots that have not yet been stamped and can be stamped by any player as their respective stamp path moves along.

### Stamped Dots
Dots that have been stamped can not be stamped by any player. The only way for a stamp to be removed is if the player backtracks their stamp path to that point. This will require coordination from players to ensure that the puzzle's unique solution is met and each player makes the correct path for their stamp.

### Starting Dots
Each player's stamp has a starting dot where they are positioned when the puzzle begins. This dot can never be stamped by another player, nor can the player remove this stamp. If they backtrack their stamp path completely then it will be the only stamp they have, and the player can begin a new stamp path from there.

### Destination Dots
For each player's stamp there is one dot that is designated as their stamps destination dot. Their path must end on that dot exactly in order for the puzzle to be solved. Thus their stamp path must do three key things:
- Contribute to filling in all the dots they are able to
- Move their stamp from their starting dot to their destination dot
- Allow for the other player's stamps to also reach their destination (not blocking their paths) 

## Stamps
Each player is given a shape which can stamp the dots.

### Moving a Stamp
The players can select the orthogonally nearest four dots to stamp. Once they stamp a dot they can then select from the four nearest to the most recent stamp.

Once a dot is stamped the shape will persist on the dot and cannot be removed unless the player back tracks their stamp.

### Stamp Paths
The paths of the stamps will thus act like snakes which cannot cross their own path or where the other paths of stamps have been. The goal is for the players to coordinate their movements in a way that stamps all the dots on the board while also moving their respective stamp to it's designated ending stamp.
