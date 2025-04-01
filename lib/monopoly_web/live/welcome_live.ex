defmodule MonopolyWeb.WelcomeLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.SetupModal

  # Initializes socket state when the LiveView mounts
  def mount(_, _, socket) do
    {:ok, assign(socket, show_modal: false)}
  end

  # Handles event when "Join Game" is clicked
  def handle_event("open_modal", _, socket) do
    {:noreply, assign(socket, show_modal: true)}
  end

  # Handles event when "Cancel" is clicked – hides the modal
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  # Renders the LiveView HTML, including the modal if show_modal is true
  def render(assigns) do
    ~H"""
    <main class="flex items-center justify-center pt-20 bg-white">
      <div class="text-center">
        <h1 class="text-6xl font-bold text-gray-800">Vancouver Housing Market</h1>
        <p class="mt-4 text-lg text-gray-600">
          Buy properties, collect rent, and outbid your rivals in this multiplayer game!
        </p>

        <button
          phx-click="open_modal"
          class="mt-8 bg-blue-600 text-white rounded-lg font-semibold px-6 py-3 hover:bg-blue-700 transition">
          Join Game
        </button>
      </div>
    </main>

    <%= if @show_modal do %>
      <.setup_modal />
    <% end %>


    """
  end
end
