defmodule MonopolyWeb.WelcomeLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.LobbyModal
  alias GameObjects.Game

  # Initializes socket state when the LiveView mounts
  def mount(_, _, socket) do
    {:ok, assign(socket, show_modal: false)}
  end

  # Handles event when "Join Game" is clicked
  def handle_event("open_modal", _, socket) do
    Game.join_game(socket.assigns.session_id)

    # Fetch the updated game state to get the list of players
    {:ok, state} = Game.get_state()
     players = state.players

    {:noreply, assign(socket, show_modal: true, players: players)}
  end

  # Handles event when "Leave Game" is clicked – removes player and hides the modal
  def handle_event("leave_game", _, socket) do
    Game.leave_game(socket.assigns.session_id)

    {:ok, state} = Game.get_state()
    players = state.players

    {:noreply, assign(socket, show_modal: false, players: players)}
  end

   # Handle session_id coming from JS hook via pushEvent
  def handle_event("set_session_id", %{"id" => id}, socket) do
    {:noreply, assign(socket, session_id: id)}
  end

  # Renders the LiveView HTML, including the modal if show_modal is true
  def render(assigns) do
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

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
      <.lobby_modal players={@players}/>
    <% end %>

    """
  end
end
