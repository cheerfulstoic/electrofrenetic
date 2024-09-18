defmodule Electrofrenetic.Game.KeyValueStores do
  use GenServer

  @default_values %{
    energy: 100.0,
    systems: %{engine: true, weapons: true, sensors: true},
    detections: %{}
  }

  @min_values %{
    energy: 0.0
  }

  @max_values %{
    energy: 100.0
  }

  def create(game_id, store_name, value) do
    server_name(game_id)
    |> GenServer.call({:create, store_name, value})

    # |> tap(fn {uuid, data} ->
    #   Phoenix.PubSub.broadcast(Electrofrenetic.PubSub, "objects", {:object_created, {uuid, data}})
    # end)
  end

  def update(game_id, store_name, uuid, fun) do
    value = get(game_id, store_name, uuid)

    fun.(value)
    |> tap(fn new_value ->
      set(game_id, store_name, uuid, new_value)
    end)
  end

  def set(game_id, store_name, uuid, value) do
    ets_name(game_id, store_name)
    |> :ets.insert({uuid, value})
  end

  def get(game_id, store_name, uuid) do
    ets_name(game_id, store_name)
    |> :ets.lookup(uuid)
    |> case do
      [] ->
        case Map.fetch(@default_values, store_name) do
          :error -> nil
          {:ok, value} -> value
        end

      [{_, value}] ->
        value
    end
  end

  def by_uuid(game_id, store_name) do
    ets_name(game_id, store_name)
    |> :ets.tab2list()
    |> Map.new()
  end

  def add_data_from(objects_by_uuid, store_name, game_id) do
    by_uuid(game_id, store_name)
    |> Enum.reduce(objects_by_uuid, fn {uuid, value}, objects_by_uuid ->
      objects_by_uuid
      |> Map.put_new(uuid, %{})
      |> Map.update!(uuid, fn values_by_store_name ->
        Map.put_new(values_by_store_name, store_name, value)
      end)
    end)
  end

  def add_data(objects_by_uuid, key, func) do
    objects_by_uuid
    |> Map.new(fn {uuid, values_by_key} ->
      {
        uuid,
        Map.put(values_by_key, key, func.(uuid, values_by_key))
      }
    end)
  end

  @impl true
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: server_name(game_id))
  end

  @impl true
  def init(game_id) do
    {:ok,
     ~w[object position velocity rotation turn_direction thrusting? energy systems missle_count target detections]a
     |> Map.new(fn store_name ->
       {store_name, :ets.new(ets_name(game_id, store_name), [:named_table, :public])}
     end)}
  end

  @impl true
  def handle_call({:create, store_name, value}, _from, store_tables) do
    uuid = Ecto.UUID.generate()

    row = {uuid, value}

    store_tables
    |> Map.get(store_name)
    |> :ets.insert(row)

    {:reply, row, store_tables}
  end

  defp server_name(game_id) do
    :"#{__MODULE__}-#{game_id}"
  end

  defp ets_name(game_id, store_name) do
    :"game-#{game_id}|#{store_name}-store"
  end
end
