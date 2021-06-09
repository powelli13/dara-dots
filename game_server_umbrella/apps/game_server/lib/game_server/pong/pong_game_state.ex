defmodule GameServer.PongGameState do
  @paddle_right_limit 0.9
  @paddle_left_limit 0.05
  @paddle_move_step 0.05

  defstruct ball_x: 0.5,
            ball_y: 0.5,
            bot_paddle_x: 0.05

  def move_bottom_paddle(state = %GameServer.PongGameState{}, direction)
      when is_atom(direction) do
    new_paddle_x =
      case direction do
        :left ->
          if state.bot_paddle_x >= @paddle_left_limit do
            state.bot_paddle_x - @paddle_move_step
          else
            state.bot_paddle_x
          end

        :right ->
          if state.bot_paddle_x <= @paddle_right_limit do
            state.bot_paddle_x + @paddle_move_step
          else
            state.bot_paddle_x
          end
      end

    %GameServer.PongGameState{state | bot_paddle_x: new_paddle_x}
  end

  def move_ball(state = %GameServer.PongGameState{}) do
    r = :rand.uniform()

    %GameServer.PongGameState{state | ball_x: r, ball_y: r}
  end
end
