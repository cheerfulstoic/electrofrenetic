defmodule Electrofrenetic.Game.MovementTicker do
  @moduledoc """
  Updates rotation based on turn direction and velocity based on thrusting
  """

  alias Electrofrenetic.Game.KeyValueStores
  alias Electrofrenetic.Game.Geometry
  alias Electrofrenetic.Game.StoreValues

  use GenServer

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: :"#{__MODULE__}|#{game_id}")
  end

  def init(game_id) do
    send(self(), :tick)

    {:ok, game_id}
  end

  def handle_info(:tick, game_id) do
    :telemetry.span([:electrofrenetic, :game, :movement_ticker, :tick], %{}, fn ->
      rotations_by_uuid = KeyValueStores.by_uuid(game_id, :rotation)

      # MovementStore.turns_by_uuid()
      KeyValueStores.by_uuid(game_id, :turn_direction)
      |> Enum.each(fn {uuid, turn_direction} ->
        rotation = Map.get(rotations_by_uuid, uuid, 0)

        adjustment_amount =
          case turn_direction do
            :left ->
              -0.1

            :right ->
              0.1

            nil ->
              nil
          end

        if adjustment_amount do
          KeyValueStores.set(
            game_id,
            :rotation,
            uuid,
            Geometry.adjust(rotation, adjustment_amount)
          )
        end
      end)

      velocities_by_uuid = KeyValueStores.by_uuid(game_id, :velocity)

      KeyValueStores.by_uuid(game_id, :thrusting?)
      |> Enum.filter(fn {_, thrusting?} -> thrusting? end)
      |> Enum.each(fn {uuid, _} ->
        {x_velocity, y_velocity} = Map.get(velocities_by_uuid, uuid, {0, 0})
        rotation = Map.get(rotations_by_uuid, uuid, 0)

        x_velocity = x_velocity + :math.cos(rotation) * 0.05
        y_velocity = y_velocity + :math.sin(rotation) * 0.05

        KeyValueStores.set(game_id, :velocity, uuid, {x_velocity, y_velocity})

        # KeyValueStores.update(game_id, :energy, uuid, & &1 - 0.2)
        KeyValueStores.update(game_id, :energy, uuid, fn percent ->
          case StoreValues.adjust(:energy, percent, &(&1 - 1.0)) do
            :error ->
              KeyValueStores.set(game_id, :thrusting?, uuid, false)

              percent

            new_percent ->
              # KeyValueStores.set(game_id, :energy, uuid, new_percent)
              new_percent
          end
        end)
      end)

      Process.send_after(self(), :tick, 50)

      {nil, %{}}
    end)

    {:noreply, game_id}
  end
end
