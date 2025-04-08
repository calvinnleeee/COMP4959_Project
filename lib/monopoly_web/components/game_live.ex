defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Components.PlayerDashboard
  alias MonopolyWeb.Components.PropertyModal
  import MonopolyWeb.Components.CardModal
  import MonopolyWeb.Components.RentModal
  import MonopolyWeb.Components.JailScreen
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's struct, which buttons are enabled,
  # and dice-related values
  def mount(_params, _session, socket) do
    # Subscribe to the backend game state updates
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, game} = Game.get_state()

    if game == %{} do
      {:ok, push_navigate(socket, to: "/", replace: true)}
    else
      {
        :ok,
        assign(
          socket,
          game: game,
          player: nil,
          id: nil,
          roll: false,
          end_turn: false,
          dice_result: nil,
          dice_values: nil,
          is_doubles: false,
          doubles_notification: nil,
          jail_notification: nil,
          show_card_modal: false,
          show_rent_modal: false,
          show_property_modal: false,
          buy_prop: false,
          upgrade_prop: false,
          sell_prop: false,
          property: nil
        )
      }
    end
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
        0 < property.upgrades &&
            property.upgrades < length(property.rent_cost) - 2 ->
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

  # Check whether the tile is property or not
  defp is_property_tile?(tile) do
    tile.type in ["brown", "blue", "railroad", "utility", "light blue", "pink", "orange", "red", "yellow", "green", "dark blue"]
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
          end_turn: false
        )
      }
    else
      {:noreply, assign(socket, game: game)}
    end
  end

  # All other events can be handled the same
  def handle_info(%{event: _, payload: game}, socket) do
    id = socket.assigns.id
    {:noreply, assign(
      socket,
      game: game,
      player: Enum.find(game.players, fn player -> player.id == id end)
    )}
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
        player: player,
        id: id,
        roll: game.current_player.id == id && !game.current_player.rolled,
        upgrade_prop: upgradeable(property, player),
        sell_prop: sellable(property, player),
        end_turn: (game.current_player.id == id) && game.current_player.rolled
      )
    }
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

      card = new_game.active_card
      show_prop_modal = is_property_tile?(new_loc)

      # show property modal
      buy_flag = show_prop_modal && buyable(new_loc, player)
      upgrade_flag = show_prop_modal && upgradeable(new_loc, player)
      sell_flag = show_prop_modal && sellable(new_loc, player)

      # Prepare notifications
      player = new_game.current_player
      property = Enum.at(new_game.properties, player.position)

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
          upgrade_prop: upgrade_flag,
          sell_prop: sell_flag,
          end_turn: player.rolled || player.in_jail,

          # regarding property
          show_property_modal: show_prop_modal,
          buy_prop: buy_flag,
          property: property,

          # Dice results for dashboard
          dice_result: sum,
          dice_values: dice,
          is_doubles: double,

          # Notifications for dashboard
          jail_notification: jail_notification,
          doubles_notification: doubles_notification,

          # If player got an instant-play card, display it
          show_card_modal:
            card != nil && elem(card.effect, 0) != :get_out_of_jail && player.id == id,
          # If player landed on another player's property, let them know
          show_rent_modal:
            card == nil && new_loc.owner != nil && new_loc.owner.id != id
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player buys or upgrades property they are on
  def handle_event("buy_prop", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player

    # Verify that it is the player's turn and they can buy
    if player.id == id && assigns.show_property_modal do
      # Buy the property and get new game state
      {:ok, game} =
        Game.buy_property(id, Enum.at(assigns.game.properties, player.position))

      {
        :noreply,
        assign(
          socket,
          game: game,
          player: game.current_player,
          # Check if player can afford further upgrades
          upgrade_prop: upgradeable(Enum.at(game.properties, player.position), player),
          sell_prop: true,
          show_property_modal: false
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
    {:noreply,
     assign(socket,
       show_property_modal: false
     )}
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

  # An empty player, for before the state is fetched.
  def default_player() do
    %{
      sprite_id: nil,
      name: nil,
      id: nil,
      in_jail: false,
      jail_turns: 0,
      money: 0,
      cards: []
    }
  end

  def render(assigns) do
    # TODO: buttons
    # - Buy house
    # - Sell house
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

    <%= if @game.winner == nil do %>
      <div class="game-container">
        <h1 class="text-xl mb-4">Monopoly Game</h1>
        <%= if @player != nil && @game.current_player.in_jail && @game.current_player.id == @id do %>
          <.jail_screen
            player={@game.current_player}
            on_roll_dice={JS.push("roll_dice")}
            on_end_turn={JS.push("end_turn")}
          />
        <% else %>

          <!-- Placeholder for game board -->
          <div class="game-board bg-green-200 h-96 w-full flex items-center justify-center">
            Game board will be here
          </div>

          <!-- Player dashboard with dice results and all notifications -->
          <.player_dashboard
            player={@player}
            current_player={@game.current_player}
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

          <!-- Modal for property action: buy || upgrade(buy) || downgrade(sell) -->
          <%= if @show_property_modal do %>
            <%= @game.current_player.money %>

        <PropertyModal.property_modal
              id="property-modal"
              show={@show_property_modal}
              property={@property}
              buy_prop={@buy_prop}
              upgrade_prop={@upgrade_prop}
              sell_prop={@sell_prop}
              on_cancel={hide_modal("property-modal")}
            />
          <% end %>

          <!-- Modal for displaying card effects : @id or "card-modal"-->
          <%= if @show_card_modal && @game.active_card do %>
            <.card_modal
              id="card-modal"
              show={@show_card_modal}
              card={@game.active_card}
            />
          <% end %>

          <!-- Modal for displaying rent payments : @id or "rent-modal"-->
          <%= if @show_rent_modal do %>
            <.rent_modal
              id="rent_modal"
              show={@show_rent_modal}
              property={Enum.at(@game.properties, @game.current_player.position)}
              dice_result={@dice_result}
            />
          <% end %>
        <% end %>
      </div>

    <% else %>
      <h1 class="text-xl font-bold">Game over! Winner: {@game.winner.name}</h1>
    <% end %>
    """
  end

  # Remove user from game
  def terminate(_reason, socket) do
    Game.set_player_inactive(socket.assigns.id)
    :ok
  end
end
