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

// Script for the basic Tic Tac Toe game
import Game from "./game";

// Video player that is used to play videos on the lip_sync LiveView
import Player from "./player";

import socket from "./socket";

// Initialize the Lobby chat object using the lobby chat container
// if it is found on the page.
LobbyChat.init(socket, document.getElementById("lobby-chat-container"));

// Initialize the Game facilitating script
Game.init(socket, "id");

let Hooks = {};
Hooks.VideoPlayer = {
  mount() {
    console.log('mounted the player!');
  }
};

import LiveSocket from "phoenix_live_view";
import {Socket} from "phoenix";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});

liveSocket.connect();

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
