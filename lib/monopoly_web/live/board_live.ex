defmodule MonopolyWeb.BoardLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's id and struct, and whether player can roll
  def mount(params, _session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, game} = Game.get_state()
    id = Map.get(params, "id")
    player = Enum.find(game.players, fn player -> player.id == id end)
    {:ok, assign(socket, game: game, id: id, player: player, roll: true)}
  end

  # Broadcasted by Game.roll_dice()
  # TODO: do these need to be separate functions? Are they handled the same?
  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # TODO: No backend yet
  def handle_info({:turn_ended, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # Broadcasted by Game.play_card()
  def handle_info({:card_played, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # When starting turn, player first clicks roll dice button
  def handle_event("roll_dice", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player == assigns.player && assigns.roll do
      # Call the backend roll_dice endpoint
      {:ok, {dice, _sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(assigns.id)

      player = new_game.current_player
      socket = assign(socket, player: player)

      # Offer player option to buy property they landed on
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
           new_loc.owner == nil do
        if offer_property(new_loc) do
          # If player accepts property, call backend to buy it (not yet impl)
        end
      end

      # If player did not roll doubles, or is in jail, disable rolling dice
      if !double || player.in_jail, do: socket = assign(socket, roll: false)

      # If player got an instant-play card, display it
      card = new_game.active_card
      if card != nil && card.effect[0] != "get_out_of_jail" do
        display_card(card)
      end

      # TODO: special handling for if player is in jail

      socket = assign(socket, game: new_game)
    end

    {:noreply, socket}
  end

  # TODO: Let player choose whether to buy property they landed on
  # Return true if user chooses to buy
  defp offer_property(tile) do
    false
  end

  # TODO: display acquired card on screen
  # Only called for instant-play cards
  defp display_card(card) do
    nil
  end

  # Let player buy a house/hotel
  def handle_event("buy_housing", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player == assigns.player do
      # Get list of properties which can be built on
      properties =
        Enum.filter(
          assigns.player.properties,
          fn property ->
            max_upgrades = length(property.rent_cost) - 2

            property.upgrades != nil &&
              ((property.upgrades < max_upgrades &&
                  property.house_price <= assigns.player.money) ||
                 (property.upgrades == max_upgrades &&
                    property.hotel_price <= assigns.player.money))
          end
        )

      if select_property(properties, true) != nil do
        # TODO: call backend for selected property (not yet impl)
      end
    end

    {:noreply, socket}
  end

  def handle_event("sell_housing", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player == assigns.player do
      # Get list of properties which have housing
      properties =
        Enum.filter(
          assigns.player.properties,
          fn property -> property.upgrades != nil && property.upgrades > 0 end
        )

      if select_property(properties, false) != nil do
        # TODO: call backend for selected property (not yet impl)
      end
    end

    {:noreply, socket}
  end

  # TODO: allow user to select property
  # Buy is true for buying and false for selling
  # Return selected property
  defp select_property(properties, buy) do
    nil
  end

  # End the turn
  def handle_event("end_turn", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player == assigns.player do
      # TODO: Call the backend end turn endpoint (not yet impl)
      # TODO: Then assign updated game to socket
      # Reset roll to true in prep for next turn
      socket = assign(socket, roll: true)
    end

    {:noreply, socket}
  end

  def render(assigns) do
    # TODO: buttons
    # - Roll dice
    # - Buy house
    # - Sell house
    # - End turn
    # - Pay jail fine?
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
