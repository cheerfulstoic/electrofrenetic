defmodule ElectrofreneticWeb.GameLive do
  alias Electrofrenetic.Game

  use ElectrofreneticWeb, :live_view

  def render(assigns) do
    ~H"""
    <div
      class="x-auto"
      phx-hook="GameBoard"
      id="game-board"
      phx-window-keydown="control-start"
      phx-window-keyup="control-stop"
    >
      <%= if @player_ship_energy do %>
        <.battery percent={Float.round(@player_ship_energy, 1)} />
      <% end %>

      <div id="lj" phx-hook="LiveJSON"></div>

      <div class="grid grid-cols-12 gap-4 h-[30rem]">
        <div class="col-span-2">
          <p class="m-4">Game ID: <strong><%= @game_id %></strong></p>

          <hr />

          <p class="m-4">Missles Left: <strong><%= @missle_count %></strong></p>

          <.systems systems={@systems} />
        </div>

        <div id="canvas-holder" class="col-span-10   canvas-holder h-[36rem]" phx-update="ignore" />
      </div>
    </div>
    """
  end

  def battery(assigns) do
    ~H"""
    <div class="flex ">
      <div class="self-center p-2 m-2"><%= @percent %>%</div>
      <div class="flex-1 border border-2 border-gray-300 rounded-lg p-2 m-2 w-f">
        <div class="w-full h-full bg-green-500 rounded-md" style={"width: #{@percent}%"}>&nbsp;</div>
      </div>
    </div>
    """
  end

  def systems(assigns) do
    # Shows a green light when enabled
    ~H"""
    <div class="grid grid-cols-1 gap-4">
      <.button class="mt-4" phx-click="toggle-system" phx-value-system="engine">
        Toggle Engine
      </.button>
      <.traffic_light enabled={@systems.engine} />

      <.button class="mt-4" phx-click="toggle-system" phx-value-system="weapons">
        Toggle Weapons
      </.button>
      <.traffic_light enabled={@systems.weapons} />

      <.button class="mt-4" phx-click="toggle-system" phx-value-system="sensors">
        Toggle Sensors
      </.button>
      <.traffic_light enabled={@systems.sensors} />
    </div>
    """
  end

  def traffic_light(assigns) do
    green_on_shadow_class =
      "shadow-[rgba(0,0,0,0.2)_0px_-1px_7px_1px,inset_#304701_0px_-1px_9px,#89FF00_0px_2px_12px]"

    green_off_shadow_class =
      "shadow-[rgba(0,0,0,0.1)_0px_-1px_3px_1px,inset_rgba(0,0,0,0.2)_0px_-1px_3px]"

    red_on_shadow_class =
      "shadow-[rgba(0,0,0,0.2)_0px_-1px_7px_1px,inset_#441313_0px_-1px_9px,rgba(255,0,0,0.5)_0px_2px_12px]"

    red_off_shadow_class =
      "shadow-[rgba(0,0,0,0.1)_0px_-1px_3px_1px,inset_rgba(68,19,19,0.5)_0px_-1px_5px]"

    ~H"""
    <div class="container flex justify-around">
      <div class="led-box h-[30px] w-1/4 my-[10px] float-left">
        <div class={[
          "led-green mx-auto w-6 h-6 bg-[#ABFF00] rounded-full",
          if(@enabled, do: green_on_shadow_class, else: green_off_shadow_class)
        ]}>
        </div>
      </div>
      <div class="led-box h-[30px] w-1/4 my-[10px] float-left">
        <div class={[
          "led-red mx-auto w-6 h-6 bg-[#F00] rounded-full",
          if(@enabled, do: red_off_shadow_class, else: red_on_shadow_class)
        ]}>
        </div>
      </div>
    </div>
    """
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
        player_ship_energy: nil,
        systems: %{engine: true, weapons: true, sensors: true},
        missle_count: 0
      )

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Electrofrenetic.PubSub, "objects")

        case Game.register(game_id, player_name) do
          {:ok, current_player} ->
            socket
            |> assign(:game_id, game_id)
            |> assign(:current_player, current_player)

          _ ->
            socket
            |> push_navigate(to: ~p"/")
            |> put_fading_flash(:error, "Player name '#{player_name}' already in use")
        end
      else
        socket
      end
      # |> push_event("update-detections", %{detections: []})
      |> LiveJson.initialize("detections_data", %{detections: []})

    {:ok, socket}
  end

  def handle_event("ready-to-render", _, socket) do
    Process.send_after(self(), :tick, 50)

    objects_by_uuid = Game.objects_by_uuid(socket.assigns.game_id)

    socket =
      socket
      # |> push_event("add-objects", %{objects_by_uuid: objects_by_uuid})
      |> update_positions()

    # {uuid, ship} = Game.spawn_ship(socket.assigns.game_id, "Brian's ship")

    missle_count =
      Game.get_missle_count(socket.assigns.game_id, socket.assigns.current_player.ship_uuid)

    socket =
      socket
      |> assign(:missle_count, missle_count)

    # |> assign(:player_ship_uuid, uuid)
    # |> push_event("assign-player-ship", %{uuid: socket.assigns.current_player.ship_uuid})

    {:noreply, socket}
  end

  def handle_event("control-start", %{"key" => "ArrowLeft"}, socket) do
    Game.set_movement(socket.assigns.game_id, socket.assigns.current_player.ship_uuid, :turn_left)

    {:noreply, socket}
  end

  def handle_event("control-start", %{"key" => "ArrowRight"}, socket) do
    Game.set_movement(
      socket.assigns.game_id,
      socket.assigns.current_player.ship_uuid,
      :turn_right
    )

    {:noreply, socket}
  end

  def handle_event("control-start", %{"key" => "ArrowUp"}, socket) do
    Game.set_movement(socket.assigns.game_id, socket.assigns.current_player.ship_uuid, :thrust)

    {:noreply, socket}
  end

  def handle_event("control-start", %{"key" => " "}, socket) do
    missle_count =
      Game.fire_or_detonate_missle(
        socket.assigns.game_id,
        socket.assigns.current_player.ship_uuid
      )

    {:noreply, assign(socket, :missle_count, missle_count)}
  end

  def handle_event("control-start", _, socket), do: {:noreply, socket}

  def handle_event("control-stop", %{"key" => "ArrowLeft"}, socket) do
    Game.set_movement(socket.assigns.game_id, socket.assigns.current_player.ship_uuid, :stop_turn)

    {:noreply, socket}
  end

  def handle_event("control-stop", %{"key" => "ArrowRight"}, socket) do
    Game.set_movement(socket.assigns.game_id, socket.assigns.current_player.ship_uuid, :stop_turn)

    {:noreply, socket}
  end

  def handle_event("control-stop", %{"key" => "ArrowUp"}, socket) do
    Game.set_movement(
      socket.assigns.game_id,
      socket.assigns.current_player.ship_uuid,
      :stop_thrust
    )

    {:noreply, socket}
  end

  def handle_event("control-stop", _, socket), do: {:noreply, socket}

  def handle_event("spawn-ship", _, socket) do
    Task.async(fn ->
      Enum.reduce(0..1_000, socket, fn _, socket ->
        Process.sleep(10)
        {uuid, ship} = Game.spawn_ship(socket.assigns.game_id, "Test ship")
      end)
    end)
    |> Task.ignore()

    {:noreply, socket}
  end

  def handle_event("toggle-system", %{"system" => system}, socket) do
    new_value =
      Game.toggle_system(
        socket.assigns.game_id,
        socket.assigns.current_player.ship_uuid,
        String.to_existing_atom(system)
      )

    {:noreply, assign(socket, :systems, new_value)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 60)

    {:noreply,
     socket
     |> update_positions()
     # |> update_rotations()
     |> update_ship_state()}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  # def handle_info({:object_created, {uuid, data}}, socket) do
  #   socket =
  #     socket
  #     |> push_event("add-object", %{uuid: uuid, data: data})
  #     # Make more efficient FIXME
  #     |> update_positions()

  #   {:noreply, socket}
  # end

  def put_fading_flash(socket, type, message) do
    Process.send_after(self(), :clear_flash, 2_000)

    put_flash(socket, type, message)
  end

  def update_ship_state(socket) do
    socket
    |> assign(
      :player_ship_energy,
      Game.get_energy(socket.assigns.game_id, socket.assigns.current_player.ship_uuid)
    )
  end

  def update_positions(socket) do
    positions_by_uuid =
      Game.positions_by_uuid(socket.assigns.game_id)
      |> Map.new(fn {uuid, {x, y}} -> {uuid, %{x: x, y: y}} end)

    rotations_by_uuid = Game.rotations_by_uuid(socket.assigns.game_id)

    detections =
      Game.get_detections(socket.assigns.game_id, socket.assigns.current_player.ship_uuid)
      |> Enum.map(fn {uuid, detection} ->
        detection
        |> Map.update!(:position, fn
          # :live ->
          #   positions_by_uuid[uuid]

          {x, y} ->
            %{x: x, y: y}
        end)

        # |> Map.put(:rotation, rotations_by_uuid[uuid])
      end)

    player_ship = %{
      position: positions_by_uuid[socket.assigns.current_player.ship_uuid],
      thrusting:
        Game.get_thrusting(socket.assigns.game_id, socket.assigns.current_player.ship_uuid),
      rotation: rotations_by_uuid[socket.assigns.current_player.ship_uuid]
    }

    socket
    # |> push_event("update-positions", %{positions_by_uuid: positions_by_uuid})
    # |> push_event("update-detections", %{detections: detections})
    |> LiveJson.push_patch("detections_data", %{detections: detections})
    |> push_event("update-player", %{ship: player_ship})
  end
end
