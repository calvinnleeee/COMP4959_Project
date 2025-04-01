defmodule MonopolyWeb.Components.LobbyModal do
  use Phoenix.Component

  # Renders the setup modal shown when the user clicks "Join Game"
  # TODO: Replace player id with name
  def lobby_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white p-6 rounded-lg shadow-lg w-96 text-center">
        <h2 class="text-xl font-bold mb-4">Lobby</h2>
        <p class="text-gray-700 mb-4">Players currently in the game:</p>

        <div class="overflow-y-auto max-h-48 mb-4">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr>
                <th class="border-b pb-2 text-sm font-semibold text-gray-600">Player ID</th>
                <th class="border-b pb-2 text-sm font-semibold text-gray-600">Money</th>
              </tr>
            </thead>
            <tbody>
              <%= for player <- @players do %>
                <tr>
                  <td class="py-1 text-sm text-gray-800"><%= player.id %></td>
                  <td class="py-1 text-sm text-gray-800">$<%= player.money %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <button
          phx-click="close_modal"
          class="mt-4 text-blue-500 hover:underline text-sm">
          Cancel
        </button>
      </div>
    </div>
    """
  end
end
