defmodule MonopolyWeb.GameLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.PlayerDashboard

  def mount(_params, _session, socket) do
    # For testing purposes, create a sample player
    # In a real app, this would come from your game state
    sample_player = %{
      id: "player-1",
      name: "Player 1",
      color: "#FF0000",
      money: 1500,
      total_worth: 2000,
      properties: [
        %{
          name: "Boardwalk",
          group: "dark_blue",
          houses: 0,
          hotel: false,
          mortgaged: false
        },
        %{
          name: "Park Place",
          group: "dark_blue",
          houses: 3,
          hotel: false,
          mortgaged: false
        }
      ],
      in_jail: false,
      get_out_of_jail_cards: 1,
      has_rolled: false
    }

    game = %{
      id: "game-1",
      current_player_id: "player-1",
      players: [sample_player]
    }

    {:ok, assign(socket,
      game: game,
      current_player: sample_player
    )}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    # In a real app, fetch the specific game by ID
    # For now just use the sample game from mount
    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    # Index route with no ID
    {:noreply, socket}
  end

  def handle_event("roll_dice", _params, socket) do
    # Simulate rolling dice
    # In a real app, communicate with your game server
    updated_player = Map.put(socket.assigns.current_player, :has_rolled, true)

    {:noreply, assign(socket,
      current_player: updated_player,
      dice_result: :rand.uniform(6) + :rand.uniform(6)
    )}
  end

  def handle_event("end_turn", _params, socket) do
    # Reset the has_rolled status for demo purposes
    updated_player = Map.put(socket.assigns.current_player, :has_rolled, false)

    {:noreply, assign(socket,
      current_player: updated_player,
      dice_result: nil
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="game-container">
      <h1 class="text-xl mb-4">Monopoly Game</h1>

      <!-- Dice result display -->
      <%= if Map.get(assigns, :dice_result) do %>
        <div class="dice-result bg-gray-100 p-4 mb-4 rounded">
          You rolled: <%= @dice_result %>
        </div>
      <% end %>

      <!-- Placeholder for game board -->
      <div class="game-board bg-green-200 h-96 w-full flex items-center justify-center">
        Game board will be here
      </div>

      <!-- Player dashboard -->
      <.player_dashboard
        player={@current_player}
        current_player_id={@game.current_player_id}
        on_roll_dice={JS.push("roll_dice")}
        on_end_turn={JS.push("end_turn")}
      />
    </div>
    """
  end
end
