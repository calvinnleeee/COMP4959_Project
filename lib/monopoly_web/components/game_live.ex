defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.PlayerDashboard
  alias GameObjects.Game

  def mount(_params, session, socket) do
    # For development/testing purpose, use sample data
    # In production this would integrate with GameObjects.Game
    # AKA do not default to player-1 in prod?
    session_id = Map.get(session, "session_id", "player-1")

    # Test sample data with backend functions once implemented
    # game = Game.join_game(session_id)
    # game = Game.start_game()

    # Create sample player and game data
    player = create_sample_player(session_id)
    game = create_sample_game(player)

    {
      :ok,
      assign(socket,
        game: game,
        player: Enum.find(game.players, fn player -> player.id == session_id end),
        roll: game.current_player.id == session_id,
        buy_prop: false,
        upgrade_prop: false,
        downgrade_prop: false,
        dice_result: nil,
        dice_values: nil,
        is_doubles: false,
        doubles_count: 0,
        doubles_notification: nil,
        jail_notification: nil
      )
    }
  end

  # Check if property is owned by player, has upgrades remaining,
  # and player can afford upgrades
  defp upgradeable(property, player) do
    property.owner == player.id &&
      property.upgrades != nil &&
      ((property.upgrades < length(property.rent_cost) - 2 &&
          property.house_price <= player.money) ||
         (property.upgrades == length(property.rent_cost) - 2 &&
            property.hotel_price <= player.money))
  end

  # Check if property is owned by player and has been upgraded
  defp downgradeable(property, player) do
    property.owner == player.id && property.upgrades != nil && property.upgrades > 0
  end

  # Broadcasted by Game.roll_dice()
  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # Broadcasted by Game.play_card()
  def handle_info({:card_played, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # TODO: display acquired card on screen
  defp display_card(card) do
    nil
  end

  # When starting turn, player first clicks roll dice button
  def handle_event("roll_dice", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can roll
    if assigns.game.current_player.id == player.id && assigns.roll do
      # Check if player is currently in jail
      was_jailed = player.in_jail

      # Call the backend roll_dice endpoint
      {:ok, {dice, sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(player.id)

      # If player got an instant-play card, display it
      card = new_game.active_card
      if card != nil && card.effect[0] != "get_out_of_jail", do: display_card(card)

      # TODO: this isn't in the dashboard, is it still necessary? Assuming no
      # Get previous rolls for jail check or initialize to empty list
      # previous_rolls = Map.get(socket.assigns, :previous_rolls, [])

      # Prepare notifications
      player = new_game.current_player

      jail_notification =
        if !was_jailed && player.in_jail do
          "You rolled doubles 3 times in a row! Go to jail!"
        else
          nil
        end

      doubles_notification =
        if double && !player.in_jail && !was_jailed do
          "You rolled doubles! Roll again."
        else
          nil
        end

      {
        :noreply,
        assign(
          socket,
          player: player,

          # If player did not roll doubles, or is/was in jail, disable rolling dice
          roll: double && !player.in_jail && !was_jailed,

          # If property is buyable enable buy_prop button
          buy_prop:
            Enum.member?(
              [
                "brown",
                "red",
                "light blue",
                "pink",
                "orange",
                "yellow",
                "green",
                "blue",
                "railroad",
                "utility"
              ],
              new_loc.type
            ) &&
              new_loc.owner == nil &&
              new_loc.buy_cost <= player.money,
          upgrade_prop: upgradeable(new_loc, player),
          downgrade_prop: downgradeable(new_loc, player),

          # Dice results for dashboard
          dice_result: sum,
          dice_values: dice,
          is_doubles: double,
          doubles_count: assigns.doubles_count + if(double, do: 1, else: 0),

          # Notifications for dashboard
          jail_notification: jail_notification,
          doubles_notification: doubles_notification
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player buys property they are on
  def handle_event("buy_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can buy
    if assigns.game.current_player.id == player.id && assigns.buy_prop do
      property = assigns.game.properties[player.position]
      # TODO: Call backend for property (not yet impl)

      {
        :noreply,
        assign(
          socket,
          buy_prop: false,
          # If property can be upgraded enable upgrade_prop button
          upgrade_prop:
            property.upgrades != nil &&
              property.upgrades < length(property.rent_cost) - 2 &&
              property.house_price <= player.money
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player buys a house/hotel on property they are on
  def handle_event("upgrade_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can upgrade the prop
    if assigns.game.current_player.id == player.id && assigns.upgrade_prop do
      property = assigns.game.properties[player.position]
      # TODO: call backend for property (not yet impl)

      {
        :noreply,
        assign(
          socket,
          # If all upgrades bought disable upgrade_prop button
          upgrade_prop: property.upgrades < length(property.rent_cost) - 2,
          downgrade_prop: true
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player sells a house/hotel on property they are on
  def handle_event("downgrade_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can downgrade the prop
    if assigns.game.current_player.id == player.id && assigns.downgrade_prop do
      property = assigns.game.properties[player.position]
      # TODO: call backend for property (not yet impl)

      {
        :noreply,
        assign(
          socket,
          upgrade_prop: true,
          # If all housing is sold, disable downgrade_prop button
          downgrade_prop: property.upgrades > 0
        )
      }
    else
      {:noreply, socket}
    end
  end

  # End the turn
  def handle_event("end_turn", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player.id == assigns.player.id do
      # TODO: Call the backend end turn endpoint (not yet impl)

      # Disable all buttons
      {
        :noreply,
        assign(
          socket,
          roll: false,
          buy_prop: false,
          upgrade_prop: false,
          downgrade_prop: false,
          dice_result: nil,
          dice_values: nil,
          is_doubles: false,
          doubles_count: 0,
          doubles_notification: nil,
          jail_notification: nil
        )
      }
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    # TODO: buttons
    # - Roll dice
    # - Buy property (enabled if landed on)?
    # - Buy house
    # - Sell house
    # - End turn
    ~H"""
    <div class="game-container">
      <h1 class="text-xl mb-4">Monopoly Game</h1>

    <!-- Placeholder for game board -->
      <div class="game-board bg-green-200 h-96 w-full flex items-center justify-center">
        Game board will be here
        <%= if @game.current_player.in_jail do %>
          <div class="absolute bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg">
            IN JAIL (Turn {@game.current_player.jail_turns})
          </div>
        <% end %>
      </div>

    <!-- Player dashboard with dice results and all notifications -->
      <.player_dashboard
        player={@game.current_player}
        current_player_id={@game.current_player.id}
        properties={@player.properties}
        on_roll_dice={JS.push("roll_dice")}
        on_end_turn={JS.push("end_turn")}
        dice_result={@dice_result}
        dice_values={@dice_values}
        is_doubles={@is_doubles}
        doubles_notification={@doubles_notification}
        doubles_count={@doubles_count}
        jail_notification={@jail_notification}
      />
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
      properties: [],
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
