import Phaser from "phaser";

let PongSpectator = {
  init(socket, spectateElemId) {
    // Ensure that we only load Pong Phaser spectator on the correct pages
    let spectateElement = document.getElementById(spectateElemId);
    if (spectateElement == null) { return; }

    const params = new URLSearchParams(document.location.search);
    if (!params.has('id')) { return; }

    socket.connect({token: window.userToken});

    this.onReady(socket, params.get('id'));
  },

  onReady(socket, gameId) {
    let pongGameChannel = socket.channel(`pong_game:${gameId}`, () => {
      return {};
    });

    this.initPhaserGame(pongGameChannel);
  },

  initPhaserGame(gameChannel) {
    // Setup channel listeners
    gameChannel.on("game_state",
    ({ballX, ballY, topPaddleX, botPaddleX, topPlayerScore, botPlayerScore, topPlayerName, botPlayerName}) => {
      moveBall(ballX, ballY);

      moveTopPaddle(topPaddleX);

      moveBotPaddle(botPaddleX);

      updateScore(topPlayerName, topPlayerScore, botPlayerName, botPlayerScore);

      redrawGameObjects();
    });

    gameChannel.on("game_over",
    ({winnerName}) => {
      updateWinner(winnerName);
    });

    gameChannel.on("player_status",
    ({position}) => {
      populateGameInstructions(position);
    });

    gameChannel.join()
      .receive("ok", (resp) => {
        return;
      })
      .receive("error", reason => console.log("join failed", reason));

    // Setup display dimension
    const boardWidth = 375;
    const boardHeight = 500;

    // Paddle width is ten percent of the board width
    // Paddle height is five percent of the board height 
    const paddleWidth = boardWidth * 0.1;
    const paddleHeight = boardHeight * 0.05;

    // Setup Phaser game
    let config = {
      type: Phaser.AUTO,
      width: boardWidth,
      height: boardHeight,
      physics: {
        default: "arcade",
        arcade: {
          gravity: { y: 0 }
        }
      },
      scene: {
        preload: preload,
        create: create,
        update: update
      }
    };

    let game = new Phaser.Game(config);

    // Setup game objects
    let whiteGraphics;
    let blueGraphics;
    let redGraphics;
    
    let topPaddle;
    let botPaddle;
    let ball;

    function preload () {
      this.load.image("background", "game_images/background.jpg");
    }

    function create () {
      // Only load the Phaser assets on certain pages
      this.add.image(boardWidth, boardHeight, "background");

      whiteGraphics = this.add.graphics({ fillStyle: { color: 0xfefefe } });
      blueGraphics = this.add.graphics({ fillStyle: { color: 0x1a8dff } });
      redGraphics = this.add.graphics({ fillStyle: { color: 0xff1a1a } });

      topPaddle = new Phaser.Geom.Rectangle(
        0,
        0,
        paddleWidth,
        paddleHeight);
      blueGraphics.fillRectShape(topPaddle);

      botPaddle = new Phaser.Geom.Rectangle(
        0,
        boardHeight * 0.95,
        paddleWidth,
        paddleHeight);
      redGraphics.fillRectShape(botPaddle);

      ball = new Phaser.Geom.Circle(250, 250, 12.5);
      whiteGraphics.fillCircleShape(ball);

      this.input.mouse.disableContextMenu();
    }

    function update () {
    }

    function redrawGameObjects() {
        whiteGraphics.clear();
        blueGraphics.clear();
        redGraphics.clear();

        whiteGraphics.fillCircleShape(ball);
        blueGraphics.fillRectShape(topPaddle);
        redGraphics.fillRectShape(botPaddle);
    }

    function moveBall(ballX, ballY) {
      if (ball != null) {
        ball.x = percentWidthToPixels(ballX);

        // Ball position comes as a percentage
        // flip this because lower Y value is closer
        // to the top of the screen in the framework.
        ball.y = percentHeightToPixels(ballY);
      }
    }

    function moveTopPaddle(topPaddleX) {
      topPaddle.x = percentWidthToPixels(topPaddleX);
    }

    function moveBotPaddle(botPaddleX) {
      botPaddle.x = percentWidthToPixels(botPaddleX);
    }

    function updateScore(topPlayerName, topPlayerScore, botPlayerName, botPlayerScore) {
      let scoreboard = document.getElementById('scoreboard');
      scoreboard.innerHTML = `${topPlayerName}: ${topPlayerScore} - ${botPlayerName}: ${botPlayerScore}`;
    }

    function updateWinner(winnerName) {
      let announcement = document.getElementById('announcement');
      announcement.innerHTML = `Game over! The winner is ${winnerName}.`;
    }

    // The server stores object positions as relative percentages
    // of the total game space. These functions are used to convert
    // server values into the percentage for the client board position.
    function percentWidthToPixels(percentage) {
      return boardWidth * percentage;
    }

    function percentHeightToPixels(percentage) {
      return boardHeight * percentage;
    }
  }
};

export default PongSpectator;
