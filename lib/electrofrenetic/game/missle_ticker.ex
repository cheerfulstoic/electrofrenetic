defmodule Electrofrenetic.Game.MissleTicker do
  alias Electrofrenetic.Game.KeyValueStores
  alias Electrofrenetic.Game.PlayerStore
  alias Electrofrenetic.Game.Geometry

  use Electrofrenetic.Game.Ticker,
    telemetry_label: :missle_ticker,
    delay: 500

  def handle_tick(game_id) do
    tick_adjustments(game_id)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn {store, uuid, value} ->
      KeyValueStores.set(game_id, store, uuid, value)
    end)
  end

  def tick_adjustments(game_id) do
    data_by_uuid =
      %{}
      |> KeyValueStores.add_data_from(:object, game_id)
      |> KeyValueStores.add_data_from(:position, game_id)
      |> KeyValueStores.add_data_from(:rotation, game_id)
      |> KeyValueStores.add_data_from(:velocity, game_id)
      |> KeyValueStores.add_data_from(:target, game_id)

    ships_by_uuid =
      data_by_uuid
      |> Enum.filter(fn {_, %{object: object}} -> object.type == :ship end)
      |> Map.new()

    data_by_uuid
    |> Enum.filter(fn {_, %{object: object}} -> object.type == :missle end)
    |> Enum.flat_map(fn {missle_uuid, missle_data} ->
      {missle_x, missle_y} = missle_data.position

      case missle_data[:target] do
        nil ->
          target =
            Enum.find(ships_by_uuid, fn {ship_uuid, ship_data} ->
              target_in_cone?(
                missle_data.position,
                ship_data.position,
                missle_data.rotation,
                {0.7, 250}
              )
            end)

          if target do
            [{:target, missle_uuid, elem(target, 0)}]
          else
            []
          end

        target_uuid ->
          target_data = Map.get(ships_by_uuid, target_uuid)

          angle =
            Geometry.target_angle(
              missle_data.position,
              missle_data.rotation,
              target_data.position
            )

          rotation_amount = angle / 8.5

          new_rotation =
            Geometry.adjust(
              missle_data.rotation,
              rotation_amount
            )

          {velocity_x, velocity_y} = missle_data.velocity
          velocity_amount = :math.sqrt(velocity_x ** 2 + velocity_y ** 2)

          new_velocity =
            {velocity_amount * :math.cos(new_rotation), velocity_amount * :math.sin(new_rotation)}

          [
            {:rotation, missle_uuid, new_rotation},
            {:velocity, missle_uuid, new_velocity}
          ]
      end
    end)
  end

  defp target_in_cone?(
         source_position,
         target_position,
         source_rotation,
         {cone_half_angle, cone_radius}
       ) do
    distance = Geometry.distance(source_position, target_position)

    if distance < cone_radius do
      target_direction = Geometry.target_direction(source_position, target_position)

      rotation_offset = abs(target_direction - source_rotation)

      rotation_offset < cone_half_angle
    end
  end
end
