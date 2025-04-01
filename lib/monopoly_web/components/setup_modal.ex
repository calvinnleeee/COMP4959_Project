defmodule MonopolyWeb.Components.SetupModal do
  use Phoenix.Component

  # Renders the setup modal shown when the user clicks "Join Game"
  def setup_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white p-6 rounded-lg shadow-lg w-96 text-center">
        <h2 class="text-xl font-bold mb-4">Join Game</h2>
        <p class="text-gray-700 mb-4">Player setup will go here.</p>

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
