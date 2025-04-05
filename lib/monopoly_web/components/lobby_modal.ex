defmodule MonopolyWeb.Components.LobbyModal do
  use Phoenix.Component
  import MonopolyWeb.Helpers.SpriteHelper

  # Renders the setup modal shown when the user clicks "Join Game"
  def lobby_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white p-6 rounded-lg shadow-lg w-96 text-center">
        <h2 class="text-5xl font-bold mb-8">Lobby</h2>
        <p class="text-gray-700 text-md mb-8">Players currently in the game:</p>

        <div class="overflow-y-auto max-h-48 mb-8">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr>
                <th class="border-b pb-2 text-sm font-semibold text-xl text-gray-600">Player</th>
                <th class="border-b pb-2 text-sm font-semibold text-xl text-gray-600">Money</th>
              </tr>
            </thead>
            <tbody>
              <%= for player <- @players do %>
                <tr>
                  <td class="py-1 text-md text-gray-800 flex items-center gap-2">
                    <img
                      src={"/images/sprites/" <> get_sprite_filename(player.sprite_id)}
                      alt="Player Sprite"
                      class="h-15 w-15 inline-block"
                    />
                    <%= player.name %>
                  </td>
                  <td class="py-1 text-md text-gray-800">$<%= player.money %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <div class="mt-6 space-y-4">
        <%= if @sprite_id == 0 do %>
          <%= if length(@players || []) >= 2 do %>
            <button
              phx-click="start_game"
              class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 transition text-lg">
              Start Game
            </button>
          <% else %>
            <p class="text-gray-600 text-md">
              Need at least 2 players to start the game.
            </p>
          <% end %>
        <% else %>
          <p class="text-gray-600 text-md">
            Waiting for Player 1 to start the game...
          </p>
        <% end %>
        </div>

        <button
          phx-click="leave_game"
          class="mt-6 text-red-500 text-lg hover:underline">
          Leave Game
        </button>
      </div>
    </div>
    """
  end
end
