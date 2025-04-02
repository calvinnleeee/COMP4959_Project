defmodule MonopolyWeb.GameLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Components.PlayerDashboard
  import MonopolyWeb.Components.BuyModal

  def mount(_params, session, socket) do
    # For development/testing purpose, use sample data
    # In production this would integrate with GameObjects.Game
    session_id = Map.get(session, "session_id", "player-1")

    # Create sample player and game data
    sample_player = create_sample_player(session_id)
    sample_game = create_sample_game(sample_player)
    sample_properties = create_sample_properties()

    {:ok, assign(socket,
      game: sample_game,
      current_player: sample_player,
      player_properties: sample_properties,
      session_id: session_id,
      dice_result: nil,
      dice_values: nil,
      is_doubles: false,
      doubles_count: 0,
      doubles_notification: nil,
      jail_notification: nil,
      show_buy_modal: false,
      current_property: nil
    )}
  end

  def handle_params(%{"id" => _id}, _uri, socket) do
    # In a real app, fetch the specific game by ID
    # For now just use the sample game from mount
    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    # Index route with no ID
    {:noreply, socket}
  end

  def handle_event("roll_dice", _params, socket) do
    # Use backend's Dice module to roll the dice
    {{die1, die2}, sum, is_doubles} = GameObjects.Dice.roll()

    # Get current doubles count or initialize to 0
    current_doubles_count = Map.get(socket.assigns, :doubles_count, 0)

    # Calculate new doubles count
    new_doubles_count = if is_doubles, do: current_doubles_count + 1, else: 0

    # Get previous rolls for jail check or initialize to empty list
    previous_rolls = Map.get(socket.assigns, :previous_rolls, [])


    # Check if player goes to jail (3 consecutive doubles)
    # Using the backend's check_for_jail function
    goes_to_jail = GameObjects.Dice.check_for_jail(previous_rolls, {{die1, die2}, sum, is_doubles})

    # Add current roll to the beginning of the list (most recent first)
    updated_rolls = [{{die1, die2}, sum, is_doubles} | previous_rolls]

    # Get current player
    current_player = socket.assigns.current_player

    # Update player state
    updated_player = current_player
      |> Map.put(:has_rolled, !is_doubles || goes_to_jail) # Only mark as rolled if not doubles or going to jail
      |> Map.put(:in_jail, goes_to_jail || current_player.in_jail)
      |> Map.put(:jail_turns, if(goes_to_jail, do: 1, else: current_player.jail_turns))

    # Prepare notifications
    jail_notification = if goes_to_jail, do: "You rolled doubles 3 times in a row! Go to jail!", else: nil
    doubles_notification = if is_doubles && !goes_to_jail, do: "You rolled doubles! Roll again.", else: nil

    # Create updated socket with all assigns explicitly defined
    {:noreply, assign(socket, %{
      current_player: updated_player,
      dice_result: sum,
      dice_values: {die1, die2},
      is_doubles: is_doubles,
      doubles_count: new_doubles_count,
      previous_rolls: updated_rolls,
      jail_notification: jail_notification,
      doubles_notification: doubles_notification
    })}
  end


  def handle_event("end_turn", _params, socket) do
    # Reset the has_rolled status and clear dice results
    updated_player = Map.put(socket.assigns.current_player, :has_rolled, false)

    # Use explicit assign with a map to ensure all values are properly set
    {:noreply, assign(socket, %{
      current_player: updated_player,
      dice_result: nil,
      dice_values: nil,
      is_doubles: false,
      doubles_count: 0,
      doubles_notification: nil,
      jail_notification: nil
    })}
  end

  def render(assigns) do
    ~H"""
    <div class="game-container">
      <h1 class="text-xl mb-4">Monopoly Game</h1>

      <!-- Placeholder for game board -->
      <div class="game-board bg-green-200 h-96 w-full flex items-center justify-center">
        Game board will be here
        <%= if @current_player.in_jail do %>
          <div class="absolute bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg">
            IN JAIL (Turn <%= @current_player.jail_turns %>)
          </div>
        <% end %>
      </div>

      <!-- Player dashboard with dice results and all notifications -->
      <.player_dashboard
        player={@current_player}
        current_player_id={@current_player.id}
        properties={@player_properties}
        on_roll_dice={JS.push("roll_dice")}
        on_end_turn={JS.push("end_turn")}
        dice_result={@dice_result}
        dice_values={@dice_values}
        is_doubles={@is_doubles}
        doubles_notification={@doubles_notification}
        doubles_count={@doubles_count}
        jail_notification={@jail_notification}
      />

      <!-- Modal for buying property : @id or "buy-modal"-->
      <%= if @show_buy_modal && @current_property do %>
        <.buy_modal id="buy-modal" show={@show_buy_modal} property={@current_property}
          on_cancel={hide_modal("buy-modal")}/>
      <% end %>

    </div>
    """
  end

  # Sample data generation for testing UI

  def create_sample_player(id) do
    %{
      id: id,
      name: "Player #{String.last(id)}",
      sprite_id: 0,
      money: 1500,
      position: 0,
      cards: [
        %{
          id: "get-out-of-jail-1",
          name: "Get Out of Jail Free",
          type: "chance",
          effect: {:get_out_of_jail, true},
          owned: true
        }
      ],
      in_jail: false,
      jail_turns: 0,
      has_rolled: false
    }
  end

  def create_sample_game(current_player) do
    %{
      players: [current_player],
      current_player: current_player,
      properties: [],
      deck: nil,
      turn: 0
    }
  end

  def create_sample_properties do
    [
      %{
        id: 1,
        name: "Boardwalk",
        type: "dark_blue",
        buy_cost: 400,
        rent_cost: [50, 200, 600, 1400, 1700, 2000],
        upgrades: 0,
        house_price: 200,
        hotel_price: 200,
        owner: "player-1"
      },
      %{
        id: 2,
        name: "Park Place",
        type: "dark_blue",
        buy_cost: 350,
        rent_cost: [35, 175, 500, 1100, 1300, 1500],
        upgrades: 3,
        house_price: 200,
        hotel_price: 200,
        owner: "player-1"
      }
    ]
  end
end
