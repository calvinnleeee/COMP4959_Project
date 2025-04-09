defmodule MonopolyWeb.WelcomeLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.LobbyModal
  alias GameObjects.Game

  # Initializes socket state when the LiveView mounts
  @impl true
  def mount(_, _, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, assign(socket, show_modal: false, game_started: false)}
  end

  # Handles event when "Join Game" is clicked
  @impl true
  def handle_event("open_modal", _, socket) do
    Game.join_game(socket.assigns.session_id)

    {:ok, state} = Game.get_state()
    players = state.players

    current_player = Enum.find(players, fn p -> p.id == socket.assigns.session_id end)
    sprite_id = current_player.sprite_id

    {:noreply, assign(socket, show_modal: true, players: players, sprite_id: sprite_id)}
  end

  # Handles event when "Leave Game" is clicked – removes player and hides the modal
  def handle_event("leave_game", _, socket) do
    Game.leave_game(socket.assigns.session_id)

    {:ok, state} = Game.get_state()
    players = if state != %{}, do: state.players, else: []

    {:noreply, assign(socket, show_modal: false, players: players)}
  end

  # Handles event when "Start Game" is clicked – starts the game and redirects
  def handle_event("start_game", _, socket) do
    Game.start_game()
    {:noreply, socket}
  end

  # Handle session_id coming from JS hook via pushEvent
  def handle_event("set_session_id", %{"id" => id}, socket) do
    {:noreply, assign(socket, session_id: id)}
  end

  # Handles real time updates when new game state is broadcast
  @impl true
  def handle_info(%{event: "game_update", payload: state}, socket) do
    current_player = Enum.find(state.players, fn p -> p.id == socket.assigns.session_id end)
    sprite_id = current_player && current_player.sprite_id || nil

    game_started = state.current_player != nil

    # If the game has started, push a navigation to redirect the user to the game screen.
    # Otherwise, do nothing and keep the user on the current page.
    socket =
      if state.current_player != nil do
        push_navigate(socket, to: "/game")
      else
        socket
      end

     {:noreply, assign(socket, players: state.players, sprite_id: sprite_id, game_started: game_started)}
  end

  # Handles real time update when game is deleted
  def handle_info(%{event: "game_deleted"}, socket) do
    {:noreply, assign(socket, players: [], show_modal: false)}
  end

  # Catch-all for handling game updates while someone is in the lobby
  def handle_info(%{event: _,}, socket) do
    {:noreply, socket}
  end

  # Renders the LiveView HTML, including the modal if show_modal is true
  @impl true
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
      <.lobby_modal players={@players} sprite_id={@sprite_id}  />
    <% end %>

    """
  end
end
