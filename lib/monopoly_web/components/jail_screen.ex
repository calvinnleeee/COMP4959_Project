defmodule MonopolyWeb.JailLive do
  use Phoenix.LiveView
  alias GameObject.Game


  def mount(_params, %{"session_id" => player_id} = _session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state:#{player_id}")
    # Initialize with 3 turns remaining, no dice roll result
    {:ok, assign(socket, player_id: player_id, turns_remaining: 3, dice: nil, result: nil)}
  end

  def handle_info({:game_update, game_state}, socket) do
    # Extract jail-related info from the game_state
    turns_remaining = game_state.jail_turns || 3
    {:noreply, assign(socket, turns_remaining: turns_remaining)}
  end

  def render(assigns) do
    ~L"""
    <div class="max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
    <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>

    <div class="jail-image">
      <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
    </div>
    <p class="text-lg mb-4">Turns remaining in jail: <%= @turns_remaining %></p>

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
      <% end %>
    </div>
    """
  end

  # Handle the "Pay $50" event
  def handle_event("pay", _params, socket) do
    {:noreply, assign(socket, turns_remaining: 0, result: "You paid $50 and are now free!")}
  end

  # Handle the "Roll Doubles" event
  def handle_event("roll_dice", _params, socket) do

    {:ok, {_dice, _sum, is_doubles}, _new_pos, _new_loc, _new_game } =
      Game.roll_dice(socket.assign.player_id)

    result =
      if is_doubles do
        "Doubles! You're free from jail!"
      else
        "Not doubles. Try again next turn."
      end

    new_turns = if is_doubles, do: 0, else: max(socket.assigns.turns_remaining - 1, 0)
    {:noreply, assign(socket, result: result, turns_remaining: new_turns)}
  end
end
