defmodule ElectrofreneticWeb.StartLive do
  alias Electrofrenetic.Game

  use ElectrofreneticWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <!-- Start or join a game -->
      <h1 class="text-3xl font-bold text-center mb-8">
        Electrofrenetic
      </h1>

      <form phx-submit="start-or-join" class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <div class="m-4">
          <label class="block text-gray-700 text-sm font-bold mb-2">
            Your Name (required)
            <input
              name="name"
              class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              autofocus
            />
          </label>
        </div>

        <div class="m-4">
          <label class="block text-gray-700 text-sm font-bold mb-2" for="username">
            Game ID (leave blank to start a new game)
          </label>
          <input
            name="game_id"
            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          />
        </div>

        <.button
          type="submit"
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
          Start or join a game
        </.button>
      </form>
    </div>
    """
  end

  # def mount(_params, _session, socket) do
  #   {:ok, assign(socket)}
  # end

  def handle_event("start-or-join", %{"game_id" => game_id, "name" => name}, socket) do
    case String.strip(name) do
      "" ->
        {:noreply, put_flash(socket, :error, "Name is required")}

      name ->
        if String.strip(game_id) == "" do
          case Game.start() do
            {:ok, game_id} ->
              {:noreply, push_navigate(socket, to: ~p"/game/#{game_id}/as/#{name}")}

            {:error, error} ->
              IO.inspect(error)

              {:noreply, socket}
          end
        else
          {:noreply, push_navigate(socket, to: ~p"/game/#{game_id}/as/#{name}")}
        end
    end
  end
end
