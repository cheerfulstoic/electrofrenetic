defmodule Electrofrenetic.Game.MomentumTicker do
  @moduledoc """
  Updates x and y positions in the ETS table every tick based on the x and y velocities.
  """

  alias Electrofrenetic.Game.KeyValueStores

  use Electrofrenetic.Game.Ticker,
    telemetry_label: :momentum_ticker,
    delay: 50

  def handle_tick(game_id) do
    velocities_by_uuid = KeyValueStores.by_uuid(game_id, :velocity)

    KeyValueStores.by_uuid(game_id, :position)
    |> Enum.each(fn {uuid, {x_position, y_position}} ->
      {x_velocity, y_velocity} = Map.get(velocities_by_uuid, uuid, {0, 0})

      new_position = {x_position + x_velocity, y_position + y_velocity}

      KeyValueStores.set(game_id, :position, uuid, new_position)
    end)
  end
end
