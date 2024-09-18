defmodule Electrofrenetic.Game.Geometry do
  @pi :math.pi()
  @two_pi 2 * @pi

  def adjust(rotation, amount) do
    normalize(rotation + amount)
  end

  def normalize(rotation) do
    cond do
      rotation < 0.0 ->
        @two_pi - rotation

      rotation > @two_pi ->
        normalize(rotation - @two_pi)

      true ->
        rotation
    end
  end

  def target_angle(source_position, source_rotation, target_position) do
    source_direction = target_direction(source_position, target_position)

    case source_direction - source_rotation do
      difference when difference > @pi ->
        difference - @two_pi

      difference ->
        difference
    end
  end

  # # Assumes that the difference that is given is never more than 2 * pi
  # def cap_difference(amount) do
  #   cond do
  #     amount > @pi ->
  #       @two_pi - amount
  #
  #     amount < -@pi ->
  #       -@two_pi - amount
  #
  #     true ->
  #       amount
  #   end
  # end
  #
  def distance(source_position, target_position) do
    {source_x, source_y} = source_position
    {target_x, target_y} = target_position

    :math.sqrt((source_x - target_x) ** 2 + (source_y - target_y) ** 2)
  end

  def target_direction(source_position, target_position) do
    {source_x, source_y} = source_position
    {target_x, target_y} = target_position

    case :math.atan2(target_y - source_y, target_x - source_x) do
      direction when direction < 0.0 ->
        direction + @two_pi

      direction ->
        direction
    end
  end
end
