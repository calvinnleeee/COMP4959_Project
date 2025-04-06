defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Components.PlayerDashboard
  import MonopolyWeb.Components.BuyModal
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's struct, which buttons are enabled,
  # and dice-related values
  def mount(_params, session, socket) do
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
    # Enable this once player.active flag exists, handles refreshing
    # game = if !player.active do Game.join_game(session_id) else game end

    # Subscribe to the backend game state updates
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")

    {
      :ok,
      assign(socket,
        game: game,
        player: player,
        # TODO: Check implementation of player.rolled
        roll: game.current_player.id == session_id && game.current_player.rolled,
        buy_prop: buyable(property, player),
        sell_prop: sellable(property, player),
        end_turn: game.current_player.id == session.id,
        dice_result: nil,
        dice_values: nil,
        is_doubles: false,
        doubles_notification: nil,
        jail_notification: nil,
        show_buy_modal: false,
        # TODO: integrate this with divergent changes
        current_property: nil
      )
    }
  end

  # Check if property is unowned, or owned by player and upgradeable
  defp buyable(property, player) do
    purchaseable = fn x, y ->
      x.owner == nil && x.buy_cost != nil && x.buy_cost <= y.money
    end

    upgradeable = fn x, y ->
      x.owner != nil && x.owner.id == y.id && x.house_price != nil &&
        cond do
          x.upgrades == 0 -> false
          x.upgrades < length(x.rent_cost) - 2 -> x.house_price < y.money
          x.upgrades == length(x.rent_cost) - 2 -> x.hotel_price < y.money
          true -> false
        end
    end

    purchaseable.(property, player) || upgradeable.(property, player)
  end

  # Check if property is owned by player
  defp sellable(property, player) do
    property.owner != nil && property.owner.id == player.id
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
        if player.turns_taken == 3 do
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
          roll: player.rolled && !player.in_jail,
          buy_prop: buyable(new_loc, player),
          sell_prop: sellable(new_loc, player),
          end_turn: !player.rolled || player.in_jail,

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

  # Player buys or upgrades property they are on
  def handle_event("buy_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can buy
    if assigns.game.current_player.id == player.id && assigns.buy_prop do
      property = Enum.at(assigns.game.properties, player.position)
      # TODO: Call backend for property (not yet impl)

      {
        :noreply,
        assign(socket, buy_prop: buyable(property, player), sell_prop: true)
      }
    else
      {:noreply, socket}
    end
  end

  # Player sells or downgrades property they are on
  def handle_event("sell_prop", _params, socket) do
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
          buy_prop: buyable(property, player),
          sell_prop: sellable(property, player)
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
          sell_prop: false,
          end_turn: false,
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

  # event handler for buy modal
  def handle_event("buy_property", _params, socket) do
    property = socket.assigns.current_property
    current_player = socket.assigns.current_player
    update_player = Map.update!(current_player, :money, fn money -> money - property.buy_cost end)

    {:noreply,
     assign(socket, %{
       current_player: update_player,
       player_properties: property,
       dice_result: nil,
       dice_values: nil,
       is_doubles: false,
       doubles_count: 0,
       doubles_notification: nil,
       jail_notification: nil,
       show_buy_modal: false,
       current_property: nil
     })}
  end

  def handle_event("cancel_buying", _params, socket) do
    {:noreply, assign(socket, show_buy_modal: false)}
  end

  def render(assigns) do
    # TODO: buttons
    # - Roll dice
    # - Buy property
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

    <!-- Modal for buying property : @id or "buy-modal"-->
      <%= if @show_buy_modal && @current_property do %>
        <.buy_modal
          id="buy-modal"
          show={@show_buy_modal}
          property={@current_property}
          on_cancel={hide_modal("buy-modal")}
        />
      <% end %>
    </div>
    """
  end

  # Remove user from game
  def terminate(_reason, socket) do
    Game.disconnect_from_game(socket.assigns.player.id)
    :ok
  end
end
