defmodule Electrofrenetic.Game.State do
  defstruct [:players, :objects]

  defmodule Player do
    defstruct [:name, :ship_uuid]
  end

  defmodule Object do
    @moduledoc """
    direction is in radians
    """

    defstruct [:uuid, :name, :position, :direction, :velocity]
  end

  def new do
    %__MODULE__{
      players: %{},
      objects: %{}
    }
  end

  def add_player(state, pid, player_name) do
    ship = %Object{
      uuid: Ecto.UUID.generate(),
      name: "#{player_name}'s ship",
      position: {0, 0.2},
      velocity: {0, 0.1}
    }

    player = %Player{name: player_name, ship_uuid: ship.uuid}

    state =
      state
      |> Map.update!(:objects, fn objects ->
        Map.put(objects, ship.uuid, ship)
      end)
      |> Map.update!(:players, fn players ->
        Map.put(players, pid, player)
      end)

    {:ok, {player, state}}
  end

  def tick(state) do
    state
    |> Map.update!(:objects, fn objects ->
      Map.new(objects, fn {uuid,
                           %{
                             position: {position_x, position_y},
                             velocity: {velocity_x, velocity_y}
                           } = object} ->
        new_position = {position_x + velocity_x, position_y + velocity_y}

        {uuid, Map.put(object, :position, new_position)}
      end)
    end)
  end

  def turn(state, ship_id, direction) do
    adjustment =
      case direction do
        :left -> -0.1
        :right -> 0.1
      end

    state
    |> Map.update!(:objects, fn objects ->
      Map.update!(objects, ship_id, fn ship ->
        %Object{ship | direction: ship.direction + adjustment}
      end)
    end)
  end

  def thrust(state, ship_id) do
    state
    |> Map.update!(:objects, fn objects ->
      Map.update!(objects, ship_id, fn ship ->
        %Object{ship | velocity: {1, 0}}
      end)
    end)
  end

  def objects(state) do
    Map.values(state.objects)
  end

  def player_pids(state) do
    Map.keys(state.players)
  end
end
