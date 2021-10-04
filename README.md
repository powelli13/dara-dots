## Game Server
This web app has some multiplayer games, including Tic Tac Toe and Pong. These games allow of players to compete against each other. The games are made using Phaser 3 in the browser, with the inndividual players being connected through WebSockets via Phoenix Channels. The game lobbies are used to let players chat and join the queues, when two players are in the queue they will be automatically matched with each other to compete in their chosen game.

## LipSync
Lip Sync is a competition in which performing teams dance and lip sync along to a playing song. The Lip Sync lobby is used to facilitate Lip Sync competitions. It allows for friendly chatting, registering your team with a YouTube video link and then starting the performance and enjoying the fun!

## DaraDots Puzzle Idea
DaraDots is cooperative puzzle game with concepts still being developed. The current working draft of the rules can be found [here](https://github.com/powelli13/dara-dots/blob/master/dara_dots_puzzle_rules.md).

## Getting Started
This web app is built using [Elixir](https://elixir-lang.org/) and the [Phoenix Web Framework](https://phoenixframework.org/). Also [Phaser 3](https://www.phaser.io/phaser3) was used in the browser to power the games. These are both required in order to run the Lip Sync web app.
Once you have Elixir and the Phoenix Framework setup:

* Clone the DaraDots repository, which contains the LipSync lobby functionality, through `git clone https://github.com/powelli13/dara-dots.git`
* In the root folder run:
  * `mix deps.get`
  * `npm install --prefix .\apps\game_server_web\assets\ install .\apps\game_server_web\assets\`
  * Change to directory `.\apps\game_server_web\assets\` and run `npx browserslist@latest --update-db`
  * Change directory back to root and run `mix phx.server` to start the web server

## Contribute
Contributions to the various games or the LipSync web app are always welcome! Here is how you can contribute:
* [Submit bugs](https://github.com/powelli13/dara-dots/issues) or issues and help to verify corrections.
* [Submit pull requests](https://github.com/powelli13/dara-dots/pulls) for bugs or suggested features.

## License
Code licensed under the [MIT License](https://github.com/powelli13/dara-dots/blob/master/LICENSE).

