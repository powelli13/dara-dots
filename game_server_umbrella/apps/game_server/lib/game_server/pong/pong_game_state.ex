defmodule GameServer.PongGameState do
  @paddle_right_limit 0.9
  @paddle_left_limit 0.0
  @paddle_move_step 0.03
  @starting_theta 197

  defstruct ball_x: 0.5,
            ball_y: 0.5,
            ball_speed: 0.02,
            # Theta here is in degrees and is converted when used
            ball_theta: @starting_theta,
            ball_x_step: 0.05,
            ball_y_step: 0.05,
            bot_paddle_x: 0.05,
            top_paddle_x: 0.05

  def move_top_paddle(state = %GameServer.PongGameState{}, direction)
      when is_atom(direction) do
    new_paddle_x = adjust_paddle_x(state.top_paddle_x, direction)

    %GameServer.PongGameState{state | top_paddle_x: new_paddle_x}
  end

  def move_bottom_paddle(state = %GameServer.PongGameState{}, direction)
      when is_atom(direction) do
    new_paddle_x = adjust_paddle_x(state.bot_paddle_x, direction)

    %GameServer.PongGameState{state | bot_paddle_x: new_paddle_x}
  end

  defp adjust_paddle_x(paddle_x, direction) do
    case direction do
      :left ->
        if paddle_x >= @paddle_left_limit do
          paddle_x - @paddle_move_step
        else
          paddle_x
        end

      :right ->
        if paddle_x <= @paddle_right_limit do
          paddle_x + @paddle_move_step
        else
          paddle_x
        end
    end
  end

  defp degrees_to_radians(degrees) do
    degrees * :math.pi() / 180
  end

  # angle of incidence equals the angle of reflection
  # find which quadrant the angle is in and then reflect it
  # need to determine if we're flipping over x or y axis

  def move_ball(state = %GameServer.PongGameState{}) do
    # check collisions
    new_theta = check_collisions_and_calculate_theta(state)

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

  defp check_collisions_and_calculate_theta(state) do
    cond do
      collide_left?(state.ball_x) ->
        reflect_left_wall(state.ball_theta)

      collide_right?(state.ball_x) ->
        reflect_right_wall(state.ball_theta)

      # TODO top and bottom walls need to make paddle checks
      collide_top?(state.ball_y) ->
        reflect_top_wall(state.ball_theta)

      collide_bottom?(state.ball_y) ->
        reflect_bottom_wall(state.ball_theta)

      true ->
        state.ball_theta
    end
  end

  defp collide_left?(ball_x), do: ball_x <= 0.1

  defp collide_right?(ball_x), do: ball_x >= 0.9

  defp collide_top?(ball_y), do: ball_y >= 0.9

  defp collide_bottom?(ball_y), do: ball_y <= 0.1

  defp reflect_left_wall(theta) do
    180 - theta
  end

  defp reflect_right_wall(theta) do
    180 - theta
  end

  defp reflect_top_wall(theta) do
    360 - theta
  end

  defp reflect_bottom_wall(theta) do
    360 - theta
  end
end
