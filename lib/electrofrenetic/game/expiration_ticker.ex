defmodule Electrofrenetic.Game.ExpirationTicker do
  @moduledoc """
  Remove objects when their expiration time has passed
  """

  alias Electrofrenetic.Game.KeyValueStores

  use Electrofrenetic.Game.Ticker,
    telemetry_label: :momentum_ticker,
    delay: 500

  def handle_tick(game_id) do
    KeyValueStores.by_uuid(game_id, :expiration)
    |> Enum.each(fn {uuid, expiration} ->
      if DateTime.compare(DateTime.utc_now(), expiration) == :gt do
        # IO.puts("DELETING #{uuid}")

        KeyValueStores.delete_object(game_id, uuid)
        # else
        #   IO.puts("NOT DELETING #{uuid}")
      end
    end)
  end
end
