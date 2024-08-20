defmodule ElectrofreneticWeb.GameLive do
  alias Electrofrenetic.Game

  use ElectrofreneticWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="x-auto">
      <p>Game ID: <strong><%= @game_id %></strong></p>

      <input phx-click="turn-left" type="button" value="Turn Left" />
      <input phx-click="turn-right" type="button" value="Turn Right" />

      <pre>|<%= inspect(@objects) %>|</pre>
      <div phx-hook="GameBoard" id="game-board" class="border border-2 h-48" data={json_encode_objects(@objects)}>

        <div id="test-me"  data={json_encode_objects(@objects)} />
      </div>
    </div>
    """
  end

  def json_encode_objects(objects) do
    Enum.map(objects, &game_object_to_map/1)
    |> Jason.encode!()
  end

  def game_object_to_map(%Game.State.Object{} = object) do
    {position_x, position_y} = object.position
    {velocity_x, velocity_y} = object.velocity
    %{
      name: object.name,
      position: %{x: position_x, y: position_y},
      direction: object.direction,
      velocity: %{x: velocity_x, y: velocity_y}
    }
  end

  def mount(%{"id" => _, "name" => ""}, _session, socket) do
    {:ok,
      socket
      |> put_fading_flash(:error, "Name is required")
      |> push_navigate(to: ~p"/")}
  end

  def mount(%{"id" => game_id, "name" => player_name}, _session, socket) do
    socket =
      assign(socket,
        game_id: game_id,
        current_player: nil,
        player_name: player_name,
        objects: []
      )

    socket =
      if connected?(socket) do
        case Game.Server.join(game_id, player_name) do
          {:ok, current_player} ->
            socket
            |> assign(:current_player, current_player)

          _ ->
            socket
            |> push_navigate(to: ~p"/")
            |> put_fading_flash(:error, "Player name '#{player_name}' already in use")
        end
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("turn-left", _, socket) do
    Game.Server.thrust(socket.assigns.game_id, socket.assigns.current_player.ship_uuid)

    {:noreply, socket}
  end

  def handle_info(%{event: :objects_update, payload: objects}, socket) do
    {:noreply, assign(socket, objects: objects)}
  end

  def put_fading_flash(socket, type, message) do
    Process.send_after(self(), :clear_flash, 2_000)

    put_flash(socket, type, message)
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end
end

