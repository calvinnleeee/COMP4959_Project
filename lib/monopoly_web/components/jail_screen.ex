defmodule MonopolyWeb.Components.JailScreen do
  use Phoenix.Component
  alias GameObject.Game
  import MonopolyWeb.CoreComponents

  attr :player, :map, required: true, doc: "The player data to display"
  attr :current_player_id, :string, default: nil, doc: "ID of the current active player"

  @impl true
  def jail_screen(assigns) do
    ~H"""
    <div id="jail-screen" class="jail-screen max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>

      <div class="jail-image">
        <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
      </div>
      <p class="text-lg mb-4">Turns remaining in jail: <%= @player.jail_turns %></p>

      <div class="flex justify-center gap-4 mb-6">
        <button
          phx-click="pay"
          phx-target={@myself}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-blue-500 hover:bg-blue-700">
          Pay $50
        </button>
        <button
          phx-click="roll_dice"
          phx-target={@myself}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-yellow-500 hover:bg-yellow-600">
          Roll Doubles
        </button>
      </div>

      <div class="mt-4 text-xl">
        <%= if @dice do %>
          <p class="my-2">You rolled: <%= Enum.join(@dice, ", ") %></p>
          <p class="font-bold mt-2"><%= @result %></p>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("pay", _params, socket) do
    updated_player = Map.put(socket.assigns.player, :jail_turns, 0)
    {:noreply, assign(socket, result: "You paid $50 and are now free!", player: updated_player)}
  end

  @impl true
  def handle_event("roll_dice", _params, socket) do
    # Assuming that player's id is stored in @player.id
    player_id = socket.assigns.player.id

    # Call the game logic to roll the dice; adjust the call as needed for your implementation.
    {:ok, {dice, _sum, is_doubles}, _new_pos, _new_loc, _new_game} =
      Game.roll_dice(player_id)

    new_turns =
      if is_doubles do
        0
      else
        max(socket.assigns.player.jail_turns - 1, 0)
      end

    result =
      if is_doubles do
        "Doubles! You're free from jail!"
      else
        "Not doubles. Try again next turn."
      end

    updated_player = Map.put(socket.assigns.player, :jail_turns, new_turns)


      {:noreply, assign(socket, dice: dice, result: result, player: updated_player)}
  end
end
