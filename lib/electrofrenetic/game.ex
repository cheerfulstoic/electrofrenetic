defmodule Electrofrenetic.Game do
  alias Electrofrenetic.Game.KeyValueStores
  alias Electrofrenetic.Game.PlayerStore

  # Tickers
  alias Electrofrenetic.Game.MomentumTicker
  alias Electrofrenetic.Game.MovementTicker
  alias Electrofrenetic.Game.EnergyTicker
  alias Electrofrenetic.Game.DetectionTicker
  alias Electrofrenetic.Game.MissleTicker

  use Supervisor

  def start do
    new_id =
      1..5
      |> Enum.map(fn _ -> 64 + :rand.uniform(26) end)
      |> to_string()

    with {:ok, _} <-
           DynamicSupervisor.start_child(
             Electrofrenetic.GameDynamicSupervisor,
             {__MODULE__, new_id}
           ) do
      {_uuid, sun} = spawn_sun(new_id)

      {:ok, new_id}
    end
  end

  def start_link(game_id) do
    Supervisor.start_link(__MODULE__, game_id, name: name(game_id))
  end

  def init(game_id) do
    children = [
      {KeyValueStores, game_id},
      {PlayerStore, game_id},
      # Tickers
      {MomentumTicker, game_id},
      {MovementTicker, game_id},
      {EnergyTicker, game_id},
      {DetectionTicker, game_id},
      {MissleTicker, game_id}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def register(game_id, player_name) do
    case Process.whereis(name(game_id)) do
      nil ->
        {:error, :not_found}

      _ ->
        {ship_uuid, ship} = spawn_ship(game_id, "#{player_name}'s ship")

        with {:ok, player} <- PlayerStore.register(game_id, self(), player_name, ship_uuid) do
          # {:ok, PlayerStore.update(game_id, self(), Map.put(player, :ship_uuid, uuid))}
          {:ok, player}
        end
    end
  end

  def objects_by_uuid(game_id), do: KeyValueStores.by_uuid(game_id, :object)
  def positions_by_uuid(game_id), do: KeyValueStores.by_uuid(game_id, :position)
  def rotations_by_uuid(game_id), do: KeyValueStores.by_uuid(game_id, :rotation)

  def get_energy(game_id, uuid), do: KeyValueStores.get(game_id, :energy, uuid)

  def get_detections(game_id, uuid), do: KeyValueStores.get(game_id, :detections, uuid)

  def get_missle_count(game_id, uuid), do: KeyValueStores.get(game_id, :missle_count, uuid)

  def toggle_system(game_id, uuid, system) when is_atom(system) do
    dbg(uuid)

    KeyValueStores.update(game_id, :systems, uuid, fn systems ->
      Map.update!(systems, system, fn x -> not x end)
    end)
  end

  def fire_missle(game_id, ship_uuid) do
    missle_count = KeyValueStores.get(game_id, :missle_count, ship_uuid)

    if KeyValueStores.get(game_id, :systems, ship_uuid).weapons && missle_count > 0 do
      {ship_x_position, ship_y_position} = KeyValueStores.get(game_id, :position, ship_uuid)
      {ship_x_velocity, ship_y_velocity} = KeyValueStores.get(game_id, :velocity, ship_uuid)
      rotation = KeyValueStores.get(game_id, :rotation, ship_uuid) || 0.0

      KeyValueStores.set(game_id, :missle_count, ship_uuid, missle_count - 1)

      KeyValueStores.create(game_id, :object, %{type: :missle})
      |> tap(fn {uuid, _} ->
        KeyValueStores.set(game_id, :position, uuid, {ship_x_position, ship_y_position})
        KeyValueStores.set(game_id, :rotation, uuid, rotation)

        missle_velocity = 0.7

        # Velocity is the ships, but with a bit in the direction of the rotation
        x_velocity = ship_x_velocity + :math.cos(rotation) * missle_velocity
        y_velocity = ship_y_velocity + :math.sin(rotation) * missle_velocity

        KeyValueStores.set(game_id, :velocity, uuid, {x_velocity, y_velocity})

        # Ship gets a bit of a kickback
        x_velocity = ship_x_velocity - :math.cos(rotation) * missle_velocity * 0.1
        y_velocity = ship_y_velocity - :math.sin(rotation) * missle_velocity * 0.1

        KeyValueStores.set(game_id, :velocity, ship_uuid, {x_velocity, y_velocity})
      end)

      missle_count - 1
    else
      missle_count
    end
  end

  def spawn_ship(game_id, name) do
    KeyValueStores.create(game_id, :object, %{type: :ship, name: name})
    |> tap(fn {uuid, _} ->
      KeyValueStores.set(game_id, :systems, uuid, %{engine: true, weapons: true, sensors: true})

      KeyValueStores.set(
        game_id,
        :position,
        uuid,
        {:rand.uniform(1_000) - 500, :rand.uniform(1_000) - 500}
      )

      velocity_x = :rand.uniform(20) / 10 - 1.0
      velocity_y = :rand.uniform(20) / 10 - 1.0
      KeyValueStores.set(game_id, :velocity, uuid, {velocity_x, velocity_y})
      KeyValueStores.set(game_id, :missle_count, uuid, 4)
    end)
  end

  def spawn_sun(game_id) do
    KeyValueStores.create(game_id, :object, %{type: :sun, name: "Sol"})
    |> tap(fn {uuid, _} ->
      KeyValueStores.set(game_id, :position, uuid, {0, 0})
    end)
  end

  # Game.start_movement(socket.assigns.player_ship_uuid, :turn_left)
  def set_movement(game_id, uuid, :turn_left),
    do: KeyValueStores.set(game_id, :turn_direction, uuid, :left)

  def set_movement(game_id, uuid, :turn_right),
    do: KeyValueStores.set(game_id, :turn_direction, uuid, :right)

  def set_movement(game_id, uuid, :stop_turn),
    do: KeyValueStores.set(game_id, :turn_direction, uuid, nil)

  def set_movement(game_id, uuid, :thrust) do
    if KeyValueStores.get(game_id, :systems, uuid).engine do
      KeyValueStores.set(game_id, :thrusting?, uuid, true)
    end
  end

  def set_movement(game_id, uuid, :stop_thrust),
    do: KeyValueStores.set(game_id, :thrusting?, uuid, false)

  defp name(game_id) do
    :"#{__MODULE__}|#{game_id}"
  end
end
