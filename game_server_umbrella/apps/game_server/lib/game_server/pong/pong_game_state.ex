defmodule GameServer.PongGameState do
  @paddle_right_limit 0.9
  @paddle_left_limit 0.0
  @paddle_move_step 0.03

  # The paddle width is ten percent
  # the front end rendering must match this
  @paddle_width 0.1

  @starting_ball_x 0.5
  @starting_ball_y 0.5
  @starting_ball_speed 0.02
  @starting_ball_x_step 0.05
  @starting_ball_y_step 0.05

  defstruct ball_x: @starting_ball_x,
            ball_y: @starting_ball_y,
            ball_speed: @starting_ball_speed,
            # Theta here is in degrees and is converted when used
            ball_theta: 90,
            ball_x_step: @starting_ball_x_step,
            ball_y_step: @starting_ball_y_step,
            top_paddle_x: 0.4,
            bot_paddle_x: 0.4,
            top_player_score: 0,
            bot_player_score: 0

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
    {new_theta, player_scored} = check_collisions_and_calculate_theta(state)

    if new_theta == :reset do
      state
      |> score_goal(player_scored)
      |> reset_ball_position_and_speed
    else
      # recalculate x and y step
      radians = degrees_to_radians(new_theta)

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

  defp check_collisions_and_calculate_theta(state) do
    cond do
      collide_left?(state.ball_x) ->
        {reflect_left_wall(state.ball_theta), :no_score}

      collide_right?(state.ball_x) ->
        {reflect_right_wall(state.ball_theta), :no_score}

      collide_bottom_paddle?(state) ->
        {reflect_paddle(state.ball_theta), :no_score}

      collide_top_paddle?(state) ->
        {reflect_paddle(state.ball_theta), :no_score}

      collide_top_goal?(state) ->
        {:reset, :bot_scored}

      collide_bottom_goal?(state) ->
        {:reset, :top_scored}

      true ->
        {state.ball_theta, :no_score}
    end
  end

  defp collide_left?(ball_x), do: ball_x <= 0.00

  defp collide_right?(ball_x), do: ball_x >= 1.00

  defp collide_bottom_paddle?(state) do
    state.ball_y >= 0.95 &&
      state.ball_x >= state.bot_paddle_x &&
      state.ball_x <= state.bot_paddle_x + @paddle_width
  end

  defp collide_top_paddle?(state) do
    state.ball_y <= 0.05 &&
      state.ball_x >= state.top_paddle_x &&
      state.ball_x <= state.top_paddle_x + @paddle_width
  end

  defp collide_top_goal?(state) do
    state.ball_y >= 0.95
  end

  defp collide_bottom_goal?(state) do
    state.ball_y <= 0.05
  end

  defp reflect_left_wall(theta) do
    180 - theta
  end

  defp reflect_right_wall(theta) do
    180 - theta
  end

  defp reflect_paddle(theta) do
    360 - theta
  end

  defp get_random_starting_theta() do
    Enum.concat(45..135, 225..315) |> Enum.random()
  end

  defp score_goal(state = %GameServer.PongGameState{}, player_scored) do
    case player_scored do
      :top_scored ->
        %GameServer.PongGameState{
          state
          | top_player_score: state.top_player_score + 1
        }

      :bot_scored ->
        %GameServer.PongGameState{
          state
          | bot_player_score: state.bot_player_score + 1
        }
    end
  end

  def reset_ball_position_and_speed(state = %GameServer.PongGameState{}) do
    %GameServer.PongGameState{
      state
      | ball_x: @starting_ball_x,
        ball_y: @starting_ball_y,
        ball_speed: @starting_ball_speed,
        ball_theta: get_random_starting_theta(),
        ball_x_step: @starting_ball_x_step,
        ball_y_step: @starting_ball_y_step
    }
  end
end
