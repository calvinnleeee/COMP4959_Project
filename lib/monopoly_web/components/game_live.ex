defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Components.PlayerDashboard
  import MonopolyWeb.Components.BuyModal
  import MonopolyWeb.Components.CardModal
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
        upgrade_prop: false,
        sell_prop: false,
        dice_result: nil,
        dice_values: nil,
        is_doubles: false,
        doubles_notification: nil,
        jail_notification: nil,
        show_buy_modal: false,
        show_card_modal: false
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

  # If it is now the user's turn, enable necessary buttons
  def handle_info(%{event: "turn_ended", payload: game}, socket) do
    IO.puts("DA WINNER IS:")
    IO.inspect(game.winner)
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
          sell_prop: sellable(property, player)
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

  # Handle session_id coming from JS hook via pushEvent
  def handle_event("set_session_id", %{"id" => id}, socket) do
    game = socket.assigns.game
    player = Enum.find(game.players, fn player -> player.id == id end)
    property = Enum.at(game.properties, player.position)

    # Re-activate player if they are reconnecting
    game =
      if !player.active do
        {:ok, new_game} = Game.set_player_active(id)
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
        end_turn: game.current_player.id == id && game.current_player.rolled
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
      {:ok, {dice, sum, _}, _new_pos, new_loc, new_game} =
        Game.roll_dice(id)

      double = elem(dice, 0) == elem(dice, 1)
      card = new_game.active_card
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
          show_buy_modal: buyable(new_loc, player),
          # If player got an instant-play card, display it
          show_card_modal: card != nil && elem(card.effect, 0) != :get_out_of_jail
        )
      }
    else
      {:noreply, socket}
    end
  end

  # Player upgrades property they are on
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

  # Player upgrades property they are on
  def handle_event("upgrade_prop", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player

    # Verify that it is the player's turn and they can upgrade
    if player.id == id && assigns.upgrade_prop do
      # Buy the property and get new game state
      {:ok, game} =
        Game.upgrade_property(
          id,
          Enum.at(assigns.game.properties, player.position)
        )

      {
        :noreply,
        assign(
          socket,
          game: game,
          # Check if player can afford further upgrades
          upgrade_prop: upgradeable(Enum.at(game.properties, player.position), player)
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
    if player.id == id && assigns.sell_prop do
      # Downgrade the property and get new game state
      {:ok, game} =
        Game.downgrade_property(
          id,
          Enum.at(assigns.game.properties, player.position)
        )

      property = Enum.at(game.properties, player.position)

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
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

    <%= if @game.winner == nil do %>
      <div class="game-container">
        <h1 class="text-xl mb-4">Monopoly Game</h1>

      <!-- Game board container -->
        <div id="board-canvas" class="game-board bg-green-200 h-96 w-full relative">
          <!-- WebGL canvas fills the container -->
          <canvas
            id="webgl-canvas"
            class="w-full h-full block"
            phx-hook="BoardCanvas"
            data-game={Jason.encode!(@game)}>
          </canvas>

          <%= if @game.current_player.in_jail do %>
            <div class="absolute top-2 left-2 bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg">
              IN JAIL (Turn <%= @game.current_player.jail_turns %>)
            </div>
          <% end %>
        </div>

      <!-- Player dashboard with dice results and all notifications -->
        <.player_dashboard
          player={Enum.find(@game.players, default_player(), fn player -> player.id == @id end)}
          current_player_id={@game.current_player.id}
          properties={get_properties(@game.players, @id)}
          on_roll_dice={JS.push("roll_dice")}
          on_end_turn={JS.push("end_turn")}
          on_upgrade_prop={JS.push("upgrade_prop")}
          on_sell_prop={JS.push("sell_prop")}
          dice_result={@dice_result}
          dice_values={@dice_values}
          is_doubles={@is_doubles}
          doubles_notification={@doubles_notification}
          doubles_count={get_doubles(@game.players, @id)}
          jail_notification={@jail_notification}
          roll={@roll}
          end_turn={@end_turn}
          upgrade_prop={@upgrade_prop}
          sell_prop={@sell_prop}
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

      <!-- Modal for displaying card effects : @id or "card-modal"-->
        <%= if @show_card_modal && @game.active_card do %>
          <.card_modal
            id="card-modal"
            show={@show_card_modal}
            card={@game.active_card}
          />
        <% end %>
      </div>
    <% else %>
      <h1 class="text-xl font-bold">Game over! Winner: {@game.winner.name}</h1>
    <% end %>
    """
  end

  # Remove user from game
  def terminate(_reason, socket) do
    id = socket.assigns.id
    {:ok, game} = Game.set_player_inactive(id)
    if game.current_player.id == id do
      if game.current_player.rolled do
        Game.end_turn(id)
      else
        Game.roll_dice(id)
      end
    end
    :ok
  end
end
