// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"

import socket from "./socket";
import "phoenix_html";

import LobbyChat from "./lobby";
import Game from "./game";

// Initialize the Lobby chat object using the lobby chat container
// if it is found on the page.
LobbyChat.init(socket, document.getElementById("lobby-chat-container"));

// Initialize the Game facilitating object.
// TODO consider changing the initializing state
Game.init(socket, "id");
