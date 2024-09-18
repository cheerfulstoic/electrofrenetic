defmodule Electrofrenetic.Game.Ticker do
  defmacro __using__(opts) do
    telemetry_label = Keyword.fetch!(opts, :telemetry_label)
    delay = Keyword.fetch!(opts, :delay)

    quote do
      use GenServer

      def start_link(game_id) do
        GenServer.start_link(__MODULE__, game_id, name: :"#{__MODULE__}|#{game_id}")
      end

      def init(game_id) do
        send(self(), :tick)

        {:ok, game_id}
      end

      def handle_info(:tick, game_id) do
        :telemetry.span([:electrofrenetic, :game, unquote(telemetry_label), :tick], %{}, fn ->
          handle_tick(game_id)

          {nil, %{}}
        end)

        Process.send_after(self(), :tick, unquote(delay))

        {:noreply, game_id}
      end
    end
  end
end
