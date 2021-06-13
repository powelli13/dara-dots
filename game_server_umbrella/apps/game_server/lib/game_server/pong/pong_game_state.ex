defmodule GameServer.PongGameState do
  @paddle_right_limit 0.9
  @paddle_left_limit 0.0
  @paddle_move_step 0.03

  defstruct ball_x: 0.5,
            ball_y: 0.5,
            ball_speed: 0.02,
            # Theta here is in degrees and is converted when used
            ball_theta: 45,
            ball_x_step: 0.05,
            ball_y_step: 0.05,
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

  defp degrees_to_radians(degrees) do
    degrees * :math.pi() / 180
  end

  # angle of incidence equals the angle of reflection
  # find which quadrant the angle is in and then reflect it
  # need to determine if we're flipping over x or y axis
  # collision with right wall

  # collision with left wall

  # collision with top

  # collision with bottom

  # reflect angles across x and y axis
  # TODO I think this can be improved still, some cases are wrong
  defp reflect_across_x(degrees) do
    abs(360 - degrees)
  end

  defp reflect_across_y(degrees) do
    abs(180 - degrees)
  end

  def move_ball(state = %GameServer.PongGameState{}) do
    # check collisions
    new_theta =
      cond do
        state.ball_x <= 0.05 ->
          45

        state.ball_x >= 0.95 ->
          225

        true ->
          state.ball_theta
      end

    # recalculate x and y step
    radians = degrees_to_radians(new_theta)

    # TODO reminder that increasing Y moves things down the screen
    new_ball_x_step = state.ball_speed * :math.cos(radians)
    new_ball_y_step = state.ball_speed * :math.sin(radians)

    # move ball
    new_ball_x = state.ball_x + new_ball_x_step
    new_ball_y = state.ball_y + new_ball_y_step

    %GameServer.PongGameState{
      state
      | ball_x: new_ball_x,
        ball_y: new_ball_y,
        ball_x_step: new_ball_x_step,
        ball_y_step: new_ball_y_step,
        ball_theta: new_theta
    }
  end
end
