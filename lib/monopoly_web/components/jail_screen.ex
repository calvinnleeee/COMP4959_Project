defmodule MonopolyWeb.Components.JailScreen do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :player, :map, required: true, doc: "The player data to display"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :on_end_turn, JS, default: %JS{}, doc: "JS command for end turn action"
  def jail_screen(assigns) do
    ~H"""
    <div id="jail-screen" class="jail-screen max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>
      <div class="jail-image">
        <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
      </div>
      <p class="text-lg mb-4">Turns remaining in jail: <%= 3 - @player.jail_turns %></p>
      <div class="flex justify-center gap-4 mb-6">
      <%= if @player.rolled do %>
        <button
          phx-click={@on_end_turn}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-gray-500 hover:bg-gray-600">
          End Turn
        </button>
      <% else %>
        <button
          phx-click={@on_roll_dice}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-yellow-500 hover:bg-yellow-600">
          Roll Dice
        </button>
      <% end %>
      </div>
    </div>
    """
  end
end
