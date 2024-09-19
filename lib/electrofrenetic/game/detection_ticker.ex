defmodule Electrofrenetic.Game.DetectionTicker do
  alias Electrofrenetic.Game.KeyValueStores
  alias Electrofrenetic.Game.PlayerStore

  use Electrofrenetic.Game.Ticker,
    telemetry_label: :detection_ticker,
    delay: 2_500

  def handle_tick(game_id) do
    tick_adjustments(game_id)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn {store, uuid, value} ->
      set(game_id, store, uuid, value)
    end)
  end

  # TODO Move this lower down?
  def set(game_id, :detections, uuid, detections) do
    # object = KeyValueStores.get(game_id, :object, uuid)

    # PlayerStore.send(game_id, uuid, {:update_detections, detections})

    KeyValueStores.set(game_id, :detections, uuid, detections)
  end

  def tick_adjustments(game_id) do
    data_by_uuid =
      %{}
      |> KeyValueStores.add_data_from(:object, game_id)
      |> KeyValueStores.add_data_from(:position, game_id)
      |> KeyValueStores.add_data_from(:rotation, game_id)
      |> KeyValueStores.add_data_from(:systems, game_id)
      |> KeyValueStores.add_data_from(:detections, game_id)
      |> KeyValueStores.add_data_from(:thrusting?, game_id)
      |> KeyValueStores.add_data_from(:target, game_id)
      |> KeyValueStores.add_data(:energy_output, fn
        uuid, %{object: %{type: :sun}} = ship ->
          1_000_000

        uuid, %{object: %{type: :explosion}} = ship ->
          1_000

        uuid, %{object: %{type: :missle}} = ship ->
          # Should maybe make these fade at some point

          1_000_000

        uuid, %{object: %{type: :ship}} = ship ->
          {x, y} = ship.position

          distance_from_sun = :math.sqrt(x ** 2 + x ** 2)

          # all systems -> 30
          # + thrusting -> 55

          # when 100 units from the sun, add 20 units
          # when 200 units from the sun, add 15 units
          # when 400 units from the sun, add 10 units
          # when 800 units from the sun, add 5 units
          # etc...

          sun_factor =
            case distance_from_sun do
              x when x < 200 -> 20
              x when x < 400 -> 15
              x when x < 800 -> 10
              x when x < 1600 -> 5
              _ -> 1
            end

          # when all systems + thrusting (55), ship should be visible from ~1000 units
          # when all systems - thrusting (30), ship should be visible from ~400 units
          # when no  systems             (0), ship should be visible from ~? units

          value_if(ship[:thrusting?], 25) +
            value_if(ship.systems.engine, 15) +
            value_if(ship.systems.weapons, 10) +
            value_if(ship.systems.sensors, 5) +
            sun_factor
      end)
      |> Enum.filter(fn {_, data} ->
        data[:position] &&
          data[:energy_output] &&
          data[:object]
      end)
      |> Map.new()

    data_by_uuid
    |> Enum.filter(fn {_, %{object: object}} -> object.type == :ship end)
    |> Enum.map(fn {seeker_uuid, seeker_data} ->
      {seeker_x, seeker_y} = seeker_data.position

      seeker_sensors_enabled? = seeker_data.systems.sensors

      detections =
        data_by_uuid
        |> Map.delete(seeker_uuid)
        |> Enum.map(fn {target_uuid, target_data} ->
          {target_x, target_y} = target_data.position

          strong_detection_distance = target_data.energy_output * 10
          weak_detection_distance = target_data.energy_output * 13

          distance = :math.sqrt((seeker_x - target_x) ** 2 + (seeker_y - target_y) ** 2)

          target_type = target_data.object.type

          case {distance, target_data.object.type, seeker_sensors_enabled?} do
            {distance, :sun, _} when distance < strong_detection_distance ->
              {target_uuid,
               %{
                 type: :sun,
                 position: target_data[:position],
                 # position: :live,
                 rotation: target_data[:rotation],
                 size: 40
               }}

            {distance, :explosion, _} when distance < strong_detection_distance ->
              {target_uuid,
               %{
                 type: :explosion,
                 position: target_data[:position],
                 # position: :live,
                 rotation: target_data[:rotation],
                 size: 100
               }}

            {distance, :missle, true} when distance < strong_detection_distance ->
              # Should maybe make these fade at a distance at some point
              # For now, just make them visible

              {target_uuid,
               %{
                 type: :missle,
                 position: target_data[:position],
                 # position: :live,
                 rotation: target_data[:rotation],
                 target_aquired: !!target_data[:target],
                 size: 10
               }}

            {distance, target_type, true} when distance < strong_detection_distance ->
              {target_uuid,
               %{
                 type: :ship,
                 position: target_data[:position],
                 # position: :live,
                 rotation: target_data[:rotation],
                 size: 20
               }}

            {distance, target_type, true} when distance < weak_detection_distance ->
              {target_uuid,
               %{
                 type: :blip,
                 position: {target_x, target_y},
                 rotation: target_data[:rotation],
                 size: 160
               }}

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Map.new()

      {:detections, seeker_uuid, detections}
    end)
  end

  def value_if(nil, _), do: 0
  def value_if(false, _), do: 0
  def value_if(true, value), do: value

  #   defp detection_for(seeker, target) do
  #     distance = :math.sqrt((seeker_x - target_x) ** 2 + (seeker_y - target_y) ** 2)

  #     if distance < 100
  #       {target_uuid, %{position: {target_x, target_y}, size: 0}}
  #     elsif distance < 200
  #       {target_uuid, %{position: {target_x, target_y}, size: 160}}
  #     else
  #       nil
  #     end
  #   end
end
