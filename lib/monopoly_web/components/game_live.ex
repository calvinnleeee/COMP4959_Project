defmodule MonopolyWeb.GameLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.PlayerDashboard
  import MonopolyWeb.Components.PropertyModal
  import MonopolyWeb.Components.CardModal
  import MonopolyWeb.Components.RentModal
  import MonopolyWeb.Components.TaxModal
  import MonopolyWeb.Components.JailScreen
  import MonopolyWeb.Components.GoModal
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's id, which buttons are enabled,
  # dice-related values, and booleans for showing modals
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
          id: nil,
          roll: false,
          end_turn: false,
          dice_result: nil,
          dice_values: nil,
          is_doubles: false,
          passed_go: false,
          doubles_notification: nil,
          jail_notification: nil,
          show_property_modal: false,
          show_card_modal: false,
          show_rent_modal: false,
          show_tax_modal: false
        )
      }
    end
  end

  # If it is now the user's turn, enable necessary buttons
  def handle_info(%{event: "turn_ended", payload: game}, socket) do
    if game.current_player.id == socket.assigns.id do
      {:noreply, assign(socket, game: game, roll: true)}
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
    player = get_player(game.players, id)

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
        end_turn: game.current_player.id == id && game.current_player.rolled
      )
    }
  end

  # When starting turn, player first clicks roll dice button
  def handle_event("roll_dice", _params, socket) do
    assigns = socket.assigns
    id = assigns.id
    player = assigns.game.current_player
    old_position = player.position

    # Verify that it is the player's turn and they can roll
    if player.id == id && assigns.roll do
      # Check if player is currently in jail
      was_jailed = player.in_jail

      # Call the backend roll_dice endpoint
      {:ok, {dice, sum, _}, _new_pos, new_loc, new_game} = Game.roll_dice(id)
      double = elem(dice, 0) == elem(dice, 1)
      card = new_game.active_card
      player = new_game.current_player

      # Prepare notifications
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
          end_turn: player.rolled || player.in_jail,

          # Dice results for dashboard
          dice_result: sum,
          dice_values: dice,
          is_doubles: double,
          passed_go: old_position > player.position && !player.in_jail,

          # Notifications for dashboard
          jail_notification: jail_notification,
          doubles_notification: doubles_notification,
          show_property_modal: new_loc.buy_cost && (new_loc.owner == nil || new_loc.owner == id),
          # If player got a card, display it
          show_card_modal: card != nil,
          # If player landed on another player's property, let them know
          show_rent_modal: new_loc.owner && new_loc.owner != id,
          # If player landed on a tax or parking tile, display it
          show_tax_modal: new_loc.type in ["parking", "tax"]
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
    if player.id == id && assigns.show_property_modal do
      # Buy the property and get new game state
      {:ok, game} =
        Game.buy_property(id, Enum.at(assigns.game.properties, player.position))

      {:noreply, assign(socket, game: game)}
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
    if player.id == id && assigns.show_property_modal do
      # Buy the property and get new game state
      {:ok, game} =
        Game.upgrade_property(
          id,
          Enum.at(assigns.game.properties, player.position)
        )

      {:noreply, assign(socket, game: game)}
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
    if player.id == id && assigns.show_property_modal do
      # Downgrade the property and get new game state
      {:ok, game} =
        Game.downgrade_property(
          id,
          Enum.at(assigns.game.properties, player.position)
        )

      {:noreply, assign(socket, game: game)}
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
          end_turn: false,
          dice_result: nil,
          dice_values: nil,
          is_doubles: false,
          doubles_notification: nil,
          jail_notification: nil,
          show_property_modal: false,
          show_card_modal: false,
          show_rent_modal: false,
          show_tax_modal: false
        )
      }
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_buying", _params, socket) do
    {:noreply, assign(socket, show_property_modal: false)}
  end

  def handle_event("close_card", _params, socket) do
    {:noreply, assign(socket, show_card_modal: false)}
  end

  def handle_event("close_rent", _params, socket) do
    {:noreply, assign(socket, show_rent_modal: false)}
  end

  def handle_event("close_tax", _params, socket) do
    {:noreply, assign(socket, show_tax_modal: false)}
  end

  def handle_event("close_go", _params, socket) do
    {:noreply, assign(socket, passed_go: false)}
  end

  def handle_event("delete_game", _params, socket) do
    _ = Game.delete_game()
    {:noreply, push_navigate(socket, to: "/", replace: true)}
  end

  def get_properties(players, id) do
    if id == nil do
      []
    else
      get_player(players, id).properties
    end
  end

  def get_doubles(players, id) do
    if id == nil do
      []
    else
      get_player(players, id).turns_taken
    end
  end

  # Find a player in the list of players
  def get_player(players, id) do
    Enum.find(
      players,
      %{
        sprite_id: nil,
        name: nil,
        id: nil,
        in_jail: false,
        jail_turns: 0,
        money: 0,
        cards: [],
        active: true,
        properties: []
      },
      fn player -> player.id == id end
    )
  end

  def render(assigns) do
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

    <%= cond do %>
      <% @game.winner != nil -> %>
        <h1 class="text-xl font-bold mb-6">Game over! Winner: {@game.winner.name}</h1>
        <button
          phx-click="delete_game"
          class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Reset
        </button>
      <% !get_player(@game.players, @id).active -> %>
        <h1 class="text-xl font-bold">You have run out of money. Better luck next time!</h1>
      <% true -> %>
        <div class="game-container">
          <%= if @game.current_player.in_jail && @game.current_player.id == @id do %>
            <!-- Jail screen -->
            <.jail_screen
              player={@game.current_player}
              dice={@dice_values}
              on_roll_dice={JS.push("roll_dice")}
              on_end_turn={JS.push("end_turn")}
            />
          <% else %>

            <!-- Game board container -->
            <div id="board-canvas" class="game-board w-full relative" style="height: calc(100vh - 6rem);">
              <!-- WebGL canvas fills the container -->
              <canvas
                id="webgl-canvas"
                class="w-full h-full block"
                phx-hook="BoardCanvas"
                data-game={Jason.encode!(@game)}>
              </canvas>
            </div>

            <!-- Player dashboard with dice results and all notifications -->
            <.player_dashboard
              player={get_player(@game.players, @id)}
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
          <% end %>

          <!-- Modal for displaying property actions -->
          <%= if @show_property_modal do %>
            <.property_modal
              id="property-modal"
              player={get_player(@game.players, @id)}
              show={@show_property_modal}
              property={Enum.at(@game.properties, @game.current_player.position)}
              on_cancel={JS.push("cancel_buying")}
            />
          <% end %>

          <!-- Modal for displaying card effects : @id or "card-modal"-->
          <%= if @show_card_modal && @game.active_card do %>
            <.card_modal
              id="card-modal"
              show={@show_card_modal}
              card={@game.active_card}
              on_cancel={JS.push("close_card")}
            />
          <% end %>

          <!-- Modal for displaying rent payments : @id or "rent-modal"-->
          <%= if @show_rent_modal do %>
            <.rent_modal
              id="rent_modal"
              show={@show_rent_modal}
              players={@game.players}
              property={Enum.at(@game.properties, @game.current_player.position)}
              dice_result={if @dice_result != nil do @dice_result else 0 end}
              on_cancel={JS.push("close_rent")}
            />
          <% end %>

          <!-- Modal for displaying tax/parking payments : @id or "tax-modal"-->
          <%= if @show_tax_modal do %>
            <.tax_modal
              id="tax_modal"
              show={@show_tax_modal}
              tile={Enum.at(@game.properties, @game.current_player.position)}
              on_cancel={JS.push("close_tax")}
            />
          <% end %>

          <!-- Modal for passing go -->
          <%= if @passed_go do %>
            <.go_modal
              id="go-modal"
              show={@passed_go}
              on_cancel={JS.push("close_go")}
            />
          <% end %>
        </div>
    <% end %>
    """
  end

  # Remove user from game
  def terminate(_reason, socket) do
    id = socket.assigns.id
    {:ok, game} = Game.set_player_inactive(id)
    if game.current_player.id == id, do: Game.end_turn(id, true)
    :ok
  end
end
