defmodule Electrofrenetic.Game.Server do
  alias Electrofrenetic.Game.State

  use GenServer

  def start do
    new_id =
      (1..5)
      |> Enum.map(fn _ -> 64 + :rand.uniform(26) end)
      |> to_string()

    with {:ok, _} <- GenServer.start(__MODULE__, new_id, name: name(new_id)) do
      {:ok, new_id}
    end
  end

  # def start_link(_) do
  #   GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  # end

  def join(game_id, player_name) do
    case Process.whereis(name(game_id)) do
      nil ->
        {:error, :not_found}

      pid ->
        GenServer.call(pid, {:join, player_name})
    end
  end

  def turn(game_id, ship_id, direction) do
    GenServer.call(name(game_id), {:turn, ship_id, direction})
  end

  def thrust(game_id, ship_id) do
    GenServer.call(name(game_id), {:thrust, ship_id})
  end

  def init(_) do
    Process.send_after(self(), :tick, 50)

    {:ok, State.new()}
  end

  def handle_call({:join, player_name}, {pid, _}, state) do
    Process.monitor(pid)

    case State.add_player(state, pid, player_name) do
      {:ok, {new_player, state}} ->
      # {:ok, {players, new_player}} ->
        # send(self(), :send_updates)
        # send(self(), :send_player_update)

        {:reply, {:ok, new_player}, state}

      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end

  def handle_call({:turn, ship_id, direction}, _from, state) do
    {:reply, :ok, State.turn(state, ship_id, direction)}
  end

  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, 50)

    broadcast(state, :objects_update, State.objects(state))

    {:noreply, State.tick(state)}
  end

  def handle_info({:thrust, ship_id}, state) do
    {:noreply, State.thrust(state, ship_id)}
  end

  defp broadcast(state, event, payload) do
    for pid <- State.player_pids(state) do
      send(pid, %{event: event, payload: payload})
    end
  end

  defp name(game_id) do
    :"#{__MODULE__}-#{game_id}"
  end
end
