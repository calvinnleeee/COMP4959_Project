defmodule MonopolyWeb.Components.JailScreen do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

<<<<<<< HEAD
  attr :player, :map, required: true, doc: "The player data to display"
  attr :current_player_id, :string, default: nil, doc: "ID of the current active player"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :dice, :list, default: nil, doc: "List of dice values rolled"
  attr :result, :string, default: nil, doc: "Result message after rolling dice"

  def jail_screen(assigns) do
    ~H"""
    <div id="jail-screen" class="jail-screen max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>

=======
  def mount(_params, %{"session_id" => player_id} = _session, socket) do
    # Load the player data, e.g., from a database or game server.
    player = Game.get_player(player_id)

    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state:#{player_id}")

    # Assign the player and any other initial data to the socket.
    {:ok, assign(socket, player: player, dice: nil, result: nil)}
  end


  def render(assigns) do
    ~H"""
    <div class="max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>

>>>>>>> 9f3eb37 (changed attr to mount)
      <div class="jail-image">
        <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
      </div>
      <p class="text-lg mb-4">Turns remaining in jail: <%= @player.jail_turns %></p>
<<<<<<< HEAD
      <div class="flex justify-center gap-4 mb-6">
        <button
          phx-click={@on_roll_dice}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-yellow-500 hover:bg-yellow-600">
          Roll Dice
        </button>
      </div>
      <div class="mt-4 text-xl">
        <%= if @dice do %>
          <p class="my-2">You rolled: <%= elem(assigns.dice, 0) %> and <%= elem(assigns.dice, 1) %></p>
          <p class="font-bold mt-2">
            <%= @result %>
          </p>
=======

      <div class="flex justify-center gap-4 mb-6">
        <button phx-click="pay" class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-blue-500 hover:bg-blue-700">
          Pay $50
        </button>
        <button phx-click="roll_dice" class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-yellow-500 hover:bg-yellow-600">
          Roll Doubles
        </button>
      </div>

      <div class="mt-4 text-xl">
        <%= if @dice do %>
          <p class="my-2">You rolled: <%= Enum.join(@dice, ", ") %></p>
          <p class="font-bold mt-2"><%= @result %></p>
>>>>>>> 9f3eb37 (changed attr to mount)
        <% end %>
      </div>
    </div>
    """
  end
end
