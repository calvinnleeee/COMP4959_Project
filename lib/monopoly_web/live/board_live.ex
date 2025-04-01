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
    player = Enum.find(game.players, fn player -> player.id == id end)

    {
      :ok,
      assign(
        socket,
        game: game,
        player: player,
        roll: false,
        buy_prop: false,
        upgrade_prop: false,
        downgrade_prop: false
      )
    }
  end

  # Broadcasted by Game.roll_dice()
  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # TODO: No backend yet, check what their atom is called
  def handle_info({:turn_ended, game}, socket) do
    # Check if it is now the player's turn
    assigns = socket.assigns

    if assigns.game.current_player.id == assigns.player.id do
      # Enable die rolling
      socket = assign(socket, roll: true)

      # If player escaped jail with card, display card on screen
      if game.active_card != nil && game.active_card.effect[0] == "get_out_of_jail" do
        display_card(game.active_card)
      end
    end

    {:noreply, assign(socket, game: game)}
  end

  # Broadcasted by Game.play_card()
  def handle_info({:card_played, game}, socket) do
    {:noreply, assign(socket, game: game)}
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
      {:ok, {dice, _sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(assigns.player.id)

      player = new_game.current_player
      socket = assign(socket, player: player)

      # If player did not roll doubles, or is/was in jail, disable rolling dice
      if !double || player.in_jail || was_jailed do
        socket = assign(socket, roll: false)
      end

      # If property is buyable enable buy_prop button
      if Enum.member?(
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
         do: socket = assign(socket, buy_prop: true)

      # If property is owned and can be upgraded enable upgrade_prop button
      if new_loc.owner == player.id &&
           new_loc.upgrades != nil &&
           ((new_loc.upgrades < length(new_loc.rent_cost) - 2 && new_loc.house_price <= player.money) ||
            (new_loc.upgrades == length(new_loc.rent_cost) - 2 && new_loc.hotel_price <= player.money)) do
        socket = assign(socket, upgrade_prop: true)
      end

      # If property is owned and can be downgraded enable downgrade_prop button
      if new_loc.owner == player.id &&
           new_loc.upgrades != nil &&
           new_loc.upgrades > 0 do
        socket = assign(socket, downgrade_prop: true)
      end

      # If player got an instant-play card, display it
      card = new_game.active_card

      if card != nil && card.effect[0] != "get_out_of_jail" do
        display_card(card)
      end

      socket = assign(socket, game: new_game)
    end

    {:noreply, socket}
  end

  # Player buys property they are on
  def handle_event("buy_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can buy
    if assigns.game.current_player.id == player.id && assigns.buy_prop do
      # TODO: Call backend for selected property (not yet impl)

      # If property can be upgraded enable upgrade_prop button
      if new_loc.upgrades != nil &&
           (new_loc.upgrades < length(new_loc.rent_cost) - 2 &&
              new_loc.house_price <= player.money) do
        socket = assign(socket, upgrade_prop: true)
      end
    end

    {:noreply, socket}
  end

  # TODO: display acquired card on screen
  defp display_card(card) do
    nil
  end

  # Player buys a house/hotel on property they are on
  def handle_event("upgrade_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can upgrade the prop
    if assigns.game.current_player.id == player.id && assigns.upgrade_prop do
      property = assigns.game.properties[player.position]
      # TODO: call backend for property (not yet impl)

      # If all upgrades bought disable upgrade_prop button
      if property.upgrades == length(property.rent_cost) - 1 do
        socket = assign(socket, upgrade_prop: false)
      end

      # Enable downgrade_prop button
      socket = assign(socket, downgrade_prop: true)
    end

    {:noreply, socket}
  end

  # Player sells a house/hotel on property they are on
  def handle_event("downgrade_prop", _params, socket) do
    assigns = socket.assigns
    player = assigns.player

    # Verify that it is the player's turn and they can downgrade the prop
    if assigns.game.current_player.id == player.id && assigns.downgrade_prop do
      property = assigns.game.properties[player.position]
      # TODO: call backend for property (not yet impl)

      # Enable upgrade_prop button
      socket = assign(socket, upgrade_prop: true)

      # If all housing is sold, disable downgrade_prop button
      if property.upgrades == 0 do
        socket = assign(socket, downgrade_prop: false)
      end
    end

    {:noreply, socket}
  end

  # End the turn
  def handle_event("end_turn", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player.id == assigns.player.id do
      # TODO: Call the backend end turn endpoint (not yet impl)

      # Disable all buttons
      socket =
        assign(
          socket,
          roll: false,
          buy_prop: false,
          upgrade_prop: false,
          downgrade_prop: false
        )
    end

    {:noreply, socket}
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
end
