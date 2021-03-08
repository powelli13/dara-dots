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

import "phoenix_html";

// JavaScript necessary for the main lobby chat
import LobbyChat from "./lobby";

// JavaScript for the RPS lobby chat
import RpsLobbyChat from "./rps_lobby";

// Script for the basic Rock Paper Scissors game
import RpsGame from "./rps_game";

import TttLobbyChat from "./ttt_lobby";

// Script for wrapping the Phaser game to connect it with a socket
import PhaserWrapper from "./phaser_wrapper";

import socket from "./socket";

// Initialize the Lobby chat object using the lobby chat container
// if it is found on the page.
LobbyChat.init(socket, document.getElementById("lobby-chat-container"));

// Initialize the RPS Lobby chat
RpsLobbyChat.init(socket, document.getElementById("rps-lobby-chat-container"));

// Initialize the Game facilitating script
RpsGame.init(socket, "id");

// Initialize the Tic Tac Toe game pieces
TttLobbyChat.init(socket, document.getElementById("ttt-lobby-chat-container"));
PhaserWrapper.init(socket, document.getElementById("phaser-wrapper"));

// Sets up the onclick listeners for collapsible lists
let coll = document.getElementsByClassName("collapsible");

for (let i = 0; i < coll.length; i++)
{
  coll[i].addEventListener("click", function() {
    this.classList.toggle("active");
    let content = this.nextElementSibling;

    if (content.style.display === "block") {
      content.style.display = "none";
    } else {
      content.style.display = "block";
    }
  });
}

// Copies the lobby share code to the user's clip board
let copyShareCodeButton = document.getElementById("copy-share-code");
if (copyShareCodeButton != null) { 
  copyShareCodeButton.addEventListener("click", function () {
    const shareCode = document.getElementById("hidden-lobby-id").value;

    navigator.clipboard.writeText(shareCode).then(
      function() {
        console.log("Successfully copied share code.");
      },
      function() {
        console.log("Failed to copy share code.");
      }
    );
  });
}

// Display the player name if one is stored
const storedPlayerName = window.localStorage.getItem("player_name");
let playerNameTextInput = document.getElementById("player_name_input");
if (storedPlayerName != null && playerNameTextInput != null) {
  playerNameTextInput.value = storedPlayerName;
}
