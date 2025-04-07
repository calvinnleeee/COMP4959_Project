defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Components.BuyModal
  import MonopolyWeb.Components.JailScreen
  import MonopolyWeb.Components.PlayerDashboard
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's struct, which buttons are enabled,
  # and dice-related values
  def mount(_params, _session, socket) do
    # Subscribe to the backend game state updates
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, game} = Game.get_state()

    {
      :ok,
      assign(
        socket,
        game: game,
        id: nil,
        roll: false,
        end_turn: false,
        dice_result: nil,
        dice_values: nil,
        is_doubles: false,
        doubles_notification: nil,
        jail_notification: nil,
        show_buy_modal: false
      )
    }
  end

  # Handle session_id coming from JS hook via pushEvent
  def handle_event("set_session_id", %{"id" => id}, socket) do
    game = socket.assigns.game
    player = Enum.find(game.players, fn player -> player.id == id end)
    property = Enum.at(game.properties, player.position)

    # Re-activate player if they are reconnecting
    game =
      if !player.active do
        {:ok, new_game} = Game.join_game(id)
        new_game
      else
        game
      end

    {
      :noreply,
      assign(
        socket,
        game: game,
        id: id,
        roll: game.current_player.id == id && !game.current_player.rolled,
        upgrade_prop: upgradeable(property, player),
        sell_prop: sellable(property, player),
        end_turn: game.current_player.id == id
      )
    }
  end

  # Check if property is unowned
  defp buyable(property, player) do
    property.owner == nil &&
      property.buy_cost != nil &&
      property.buy_cost <= player.money
  end

  # Check if property owned by player and upgradeable
  defp upgradeable(property, player) do
    property.owner != nil &&
      property.owner.id == player.id &&
      property.house_price != nil &&
      cond do
        0 < property.upgrades < length(property.rent_cost) - 2 ->
          property.house_price < player.money

        property.upgrades == length(property.rent_cost) - 2 ->
          property.hotel_price < player.money

        true ->
          false
      end
  end

  # Check if property is owned by player
  defp sellable(property, player) do
    property.owner != nil && property.owner.id == player.id
  end

  # If it is now the user's turn, enable necessary buttons
  def handle_info(%{event: "turn_ended", payload: game}, socket) do
    if game.current_player.id == socket.assigns.id do
      player = game.current_player
      property = Enum.at(game.properties, player.position)

      {
        :noreply,
        assign(
          socket,
          game: game,
          roll: true,
          upgrade_prop: upgradeable(property, player),
          sell_prop: sellable(property, player),
          end_turn: true
        )
      }
    else
      {:noreply, assign(socket, game: game)}
    end
  end

  # All other events can be handled the same
  def handle_info(%{event: _, payload: game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # TODO: display acquired card on screen
  defp display_card(card) do
    nil
  end

  # When starting turn, player first clicks roll dice button
  def handle_event("roll_dice", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player

    # Verify that it is the player's turn and they can roll
    if player.id == id && assigns.roll do
      # Check if player is currently in jail
      was_jailed = player.in_jail

      # Call the backend roll_dice endpoint
      {:ok, {dice, sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(id)

      # If player got an instant-play card, display it
      card = new_game.active_card
      if card != nil && Enum.at(card.effect, 0) != "get_out_of_jail" do
        display_card(card)
      end

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
          game: new_game,

          # If player did not roll doubles, or is/was in jail, disable rolling dice
          roll: !player.rolled && !player.in_jail,
          upgrade_prop: upgradeable(new_loc, player),
          sell_prop: sellable(new_loc, player),
          end_turn: player.rolled || player.in_jail,

          # Dice results for dashboard
          dice_result: sum,
          dice_values: dice,
          is_doubles: double,

          # Notifications for dashboard
          jail_notification: jail_notification,
          doubles_notification: doubles_notification,

          show_buy_modal: buyable(new_loc, player)
        )
      }
    else
      {:noreply, socket}
    end
  end

  def handle_event("jail_roll", _params, socket) do
    # Use backend's Dice module to roll the dice
    {{die1, die2}, sum, is_doubles} = GameObjects.Dice.roll()

    # Get current player
    current_player = socket.assigns.current_player

    # Calculate new jail turns; if doubles then jail turns become 0,
    # otherwise decrement jail_turns by 1
    new_jail_turns = if is_doubles, do: 0, else: current_player.jail_turns - 1

    # Determine if the player should remain in jail:
    # If they rolled doubles or have exhausted their jail turns (i.e., new_jail_turns == 0),
    # then they are no longer in jail.
    in_jail = if is_doubles or new_jail_turns == 0, do: false, else: true

    # Update player state
    updated_player = current_player
      |> Map.put(:has_rolled, true)
      |> Map.put(:jail_turns, new_jail_turns)
      |> Map.put(:in_jail, in_jail)


      # Prepare notifications with an additional condition for served time
      jail_notification =
        cond do
          is_doubles ->
            "You rolled doubles! You're out of jail."
          new_jail_turns == 0 ->
            "You have served your time. You're out of jail."
          true ->
            "No doubles. Wait another turn."
        end

    # Create updated socket with all assigns explicitly defined
    {:noreply, assign(socket, %{
      current_player: updated_player,
      dice_result: sum,
      dice_values: {die1, die2},
      is_doubles: is_doubles,
      doubles_count: 0,
      previous_rolls: [],
      jail_notification: jail_notification,
      doubles_notification: nil
    })}
  end




  # Player buys or upgrades property they are on
  def handle_event("buy_prop", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player

    # Verify that it is the player's turn and they can buy
    if player.id == id && assigns.show_buy_modal do
      # Buy the property and get new game state
      {:ok, game} =
        Game.buy_property(id, Enum.at(assigns.game.properties, player.position))

      {
        :noreply,
        assign(
          socket,
          game: game,
          # Check if player can afford further upgrades
          upgrade_prop: upgradeable(Enum.at(game.properties, player.position), player),
          sell_prop: true,
          show_buy_modal: false
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player sells or downgrades property they are on
  def handle_event("sell_prop", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player

    # Verify that it is the player's turn and they can downgrade the prop
    if player.id == id && assigns.downgrade_prop do
      # Downgrade the property and get new game state
      {:ok, game} =
        Game.downgrade_property(
          id,
          Enum.at(assigns.game.properties, player.position)
        )

      property = Enum.at(assigns.game.properties, player.position)

      {
        :noreply,
        assign(
          socket,
          game: game,
          upgrade_prop: upgradeable(property, player),
          # Check if property can be further downgraded
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
    id = assigns.id

    # Verify that it is the player's turn
    if assigns.game.current_player.id == id do
      # Call backend to end the turn and get new game state
      {:ok, game} = Game.end_turn(id)


      # Disable all buttons
      {
        :noreply,
        assign(
          socket,
          game: game,
          roll: false,
          upgrade_prop: false,
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

  def handle_event("cancel_buying", _params, socket) do
    {:noreply, assign(socket, show_buy_modal: false)}
  end

  def get_properties(players, id) do
    if id == nil do
      []
    else
      Enum.find(players, fn player -> player.id == id end).properties
    end
  end

  def get_doubles(players, id) do
    if id == nil do
      []
    else
      Enum.find(players, fn player -> player.id == id end).turns_taken
    end
  end
  def render(assigns) do
    # TODO: buttons
    # - Buy house
    # - Sell house
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

    <div class="game-container">
      <h1 class="text-xl mb-4">Monopoly Game</h1>
      <%= if @game.current_player.in_jail do %>
        <.jail_screen
        player={@current_player}
        current_player_id={@current_player.id}
        on_roll_dice={JS.push("jail_roll")}
        dice={@dice_values}
        result={@jail_notification}
      />

      <%else %>


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
        properties={get_properties(@game.players, @id)}
        on_roll_dice={JS.push("roll_dice")}
        on_end_turn={JS.push("end_turn")}
        dice_result={@dice_result}
        dice_values={@dice_values}
        is_doubles={@is_doubles}
        doubles_notification={@doubles_notification}
        doubles_count={get_doubles(@game.players, @id)}
        jail_notification={@jail_notification}
        roll={@roll}
        end_turn={@end_turn}
      />

    <!-- Modal for buying property : @id or "buy-modal"-->
      <%= if @show_buy_modal do %>
        <.buy_modal
          id="buy-modal"
          show={@show_buy_modal}
          property={Enum.at(@game.properties, @game.current_player.position)}
          on_cancel={hide_modal("buy-modal")}
        />
      <% end %>
      <%end%>
    </div>
    """
  end


  # Remove user from game
  def terminate(_reason, socket) do
    Game.set_player_inactive(socket.assigns.id)
    :ok
  end
end
