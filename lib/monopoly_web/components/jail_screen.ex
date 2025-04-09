defmodule MonopolyWeb.Components.JailScreen do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import MonopolyWeb.Helpers.SpriteHelper

  attr :player, :map, required: true, doc: "The player data to display"
  attr :dice, :any, required: true, doc: "The dice rolled by the player (tuple)"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :on_end_turn, JS, default: %JS{}, doc: "JS command for end turn action"
  def jail_screen(assigns) do
    ~H"""
    <div id="jail-screen" class="jail-screen max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>
      <div class="jail-image" style="position: relative;">
        <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
        <img
          src={"/images/sprites/" <> get_sprite_filename(@player.sprite_id)}
          alt="Player Sprite"
          style="position: absolute; width: 25%; top: 6%; left: 37%; image-rendering: pixelated;"
        />
      </div>
      <p class="text-lg mb-4">Turns remaining in jail: <%= 3 - @player.jail_turns %></p>
      <div class="flex flex-col justify-center gap-4 mb-6">
      <%= if @player.rolled do %>
        <p class="mb-4">You rolled: <%= elem(@dice, 0) %> + <%= elem(@dice, 1) %></p>
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
