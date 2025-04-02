defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.PlayerDashboard
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's struct, which buttons are enabled,
  # and dice-related values
  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    # For development/testing purpose, use sample data
    # In production this would integrate with GameObjects.Game
    # AKA do not default to player-1 in prod?
    session_id = Map.get(session, "session_id", "player-1")

    # Sample game for use until lobby is complete
    {:ok, game} = Game.join_game(session_id)
    {:ok, game} = Game.join_game("player-2")
    {:ok, game} = Game.start_game()
    player = Enum.find(game.players, fn player -> player.id == session_id end)
    property = Enum.at(game.properties, player.position)

    {
      :ok,
      assign(socket,
        game: game,
        player: player,
        roll: game.current_player.id == session_id && game.current_player.rolled,
        buy_prop: buyable(property, player),
        upgrade_prop: upgradeable(property, player),
        downgrade_prop: downgradeable(property, player),
        dice_result: nil,
        dice_values: nil,
        is_doubles: false,
        doubles_notification: nil,
        jail_notification: nil
      )
    }
  end

  # Check if property is buyable
  defp buyable(property, player) do
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
      property.type
    ) &&
      property.owner == nil &&
      property.buy_cost <= player.money
  end

  # Check if property is owned by player, has upgrades remaining,
  # and player can afford upgrades
  defp upgradeable(property, player) do
    property.owner != nil &&
      property.owner.id == player.id &&
      property.upgrades != nil &&
      property.upgrades > 0 &&
      property.type != "railroad" &&
      property.type != "utility" &&
      ((property.upgrades < length(property.rent_cost) - 2 &&
          property.house_price <= player.money) ||
         (property.upgrades == length(property.rent_cost) - 2 &&
            property.hotel_price <= player.money))
  end

  # Check if property is owned by player and has been upgraded
  defp downgradeable(property, player) do
    property.owner != nil &&
      property.owner.id == player.id &&
      property.upgrades != nil &&
      property.upgrades > 1 &&
      property.type != "railroad" &&
      property.type != "utility"
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
          roll: player.rolled,
          buy_prop: buyable(new_loc, player),
          upgrade_prop: upgradeable(new_loc, player),
          downgrade_prop: downgradeable(new_loc, player),

          # Dice results for dashboard
          dice_result: sum,
          dice_values: dice,
          is_doubles: double,

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
      property = Enum.at(assigns.game.properties, player.position)
      # TODO: Call backend for property (not yet impl)

      {
        :noreply,
        assign(
          socket,
          buy_prop: false,
          upgrade_prop: upgradeable(property, player)
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
      property = Enum.at(assigns.game.properties, player.position)
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
      property = Enum.at(assigns.game.properties, player.position)
      # TODO: call backend for property (not yet impl)

      {
        :noreply,
        assign(
          socket,
          upgrade_prop: true,
          # If all housing is sold, disable downgrade_prop button
          downgrade_prop: property.upgrades > 1
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
        doubles_count={@player.turns_taken}
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
      position: 1,
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
      has_rolled: false,
      turns_taken: 0
    }
  end

  def create_sample_game(current_player) do
    %{
      players: [current_player],
      current_player: current_player,
      properties: create_sample_properties(),
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
