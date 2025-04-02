defmodule MonopolyWeb.BoardLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's struct, and which buttons are enabled
  def mount(params, _session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, game} = Game.get_state()
    id = Map.get(params, "id")

    {
      :ok,
      assign(
        socket,
        game: game,
        player: Enum.find(game.players, fn player -> player.id == id end),
        roll: game.current_player.id == id,
        buy_prop: false,
        upgrade_prop: false,
        downgrade_prop: false
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

  # TODO: No backend yet, check what their atom is called
  def handle_info({:turn_ended, game}, socket) do
    # Check if it is now the player's turn
    assigns = socket.assigns
    player = assigns.player

    if assigns.game.current_player.id == player.id do
      # If player escaped jail with card, display card on screen
      if game.active_card != nil && game.active_card.effect[0] == "get_out_of_jail",
        do: display_card(game.active_card)

      property = assigns.game.properties[player.position]

      # Update game state and enable necessary buttons
      {
        :noreply,
        assign(
          socket,
          game: game,
          roll: true,
          upgrade_prop: upgradeable(property, player),
          downgrade_prop: downgradeable(property, player)
        )
      }
    else
      {:noreply, assign(socket, game: game)}
    end
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
      # TODO: pass roll results to dashboard
      {:ok, {dice, _sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(player.id)

      # If player got an instant-play card, display it
      card = new_game.active_card
      if card != nil && card.effect[0] != "get_out_of_jail", do: display_card(card)

      {
        :noreply,
        assign(
          socket,
          player: new_game.current_player,

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
          downgrade_prop: downgradeable(new_loc, player)
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
          downgrade_prop: false
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
    <div>
      <button
        phx-click="roll_dice"
        disabled={
          @game.current_player != @player &&
            @step == "roll_dice"
        }
      >
        Roll Dice
      </button>
      <br /><br />
      <p>{inspect(@player)}</p>
      <p>{inspect(@game)}</p>
    </div>
    """
  end

  # Remove user from game
  def terminate(_reason, socket) do
    Game.leave_game(socket.assigns.player.id)
    :ok
  end
end
