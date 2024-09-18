defmodule Electrofrenetic.Game.EnergyTicker do
  alias Electrofrenetic.Game.KeyValueStores
  alias Electrofrenetic.Game.StoreValues

  use Electrofrenetic.Game.Ticker,
    telemetry_label: :energy_ticker,
    delay: 1_000

  def handle_tick(game_id) do
    positions_by_uuid = KeyValueStores.by_uuid(game_id, :position)
    systems_by_uuid = KeyValueStores.by_uuid(game_id, :systems)

    KeyValueStores.by_uuid(game_id, :energy)
    |> Enum.each(fn {uuid, percent} ->
      {position_x, position_y} = Map.get(positions_by_uuid, uuid, {0, 0})

      distance_from_sun = :math.sqrt(position_x ** 2 + position_y ** 2)

      systems_adjustment =
        Map.get(systems_by_uuid, uuid)
        |> Enum.reduce(0, fn
          {system, false}, sum -> sum - 0
          {:sensors, true}, sum -> sum - 0.1
          {:weapons, true}, sum -> sum - 0.1
          {:engine, true}, sum -> sum - 0.3
        end)

      # The closer you are to the sun, the more energy you get
      sun_adjustment =
        case distance_from_sun do
          x when x < 200 -> 2.0
          x when x < 500 -> 0.8
          x when x < 1600 -> 0.4
          x when x < 4000 -> 0.1
          _ -> 0.01
        end

      case StoreValues.adjust(:energy, percent, &(&1 + systems_adjustment + sun_adjustment)) do
        new_percent when new_percent != :error ->
          # dbg(new_percent)
          KeyValueStores.set(game_id, :energy, uuid, new_percent)
      end
    end)
  end
end
