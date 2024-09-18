defmodule Electrofrenetic.Game.PlayerStore do
  use Agent

  def start_link(game_id) do
    Agent.start_link(fn -> {%{}, %{}} end, name: name(game_id))
  end

  def register(game_id, pid, player_name, ship_uuid) do
    Agent.get_and_update(name(game_id), fn {players_by_pid, pids_by_ship_uuid} ->
      players_by_pid
      |> Enum.find(fn {_, player} -> player.name == player_name end)
      |> case do
        nil ->
          player = %{name: player_name, ship_uuid: ship_uuid, pid: pid}

          IO.inspect("SETTING pids_by_ship_uuid to {#{inspect(ship_uuid)}, #{inspect(pid)}}")

          {
            {:ok, player},
            {
              Map.put(players_by_pid, pid, player),
              Map.put(pids_by_ship_uuid, ship_uuid, pid)
            }
          }

        _ ->
          {
            {:error, :already_registered},
            {players_by_pid, pids_by_ship_uuid}
          }
      end
    end)
  end

  def get(game_id, pid) do
    Agent.get(name(game_id), fn {players_by_pid, _} ->
      Map.get(players_by_pid, pid)
    end)
  end

  def update(game_id, pid, player) do
    Agent.get_and_update(name(game_id), fn {players_by_pid, pids_by_ship_uuid} ->
      {
        player,
        {
          Map.put(players_by_pid, pid, player),
          pids_by_ship_uuid
        }
      }
    end)
  end

  def send(game_id, ship_uuid, message) do
    Agent.get(name(game_id), fn {_, pids_by_ship_uuid} ->
      # dbg(ship_uuid)
      # dbg(pids_by_ship_uuid)
      pid = Map.get(pids_by_ship_uuid, ship_uuid)

      send(pid, message)
    end)
  end

  defp name(game_id) do
    :"#{__MODULE__}|#{game_id}"
  end
end
