defmodule MonopolyWeb.BackendTestingLive do
  require Logger
  use MonopolyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")

    button_states = %{
      roll_dice: false,
      buy_property: false,
      upgrade: false,
      downgrade: false,
      end_turn: false,
      leave_game: false
    }

    {:ok,
     assign(socket,
       message: nil,
       game: nil,
       session_id: nil,
       button_states: button_states,
       dice_roll: 0
     )}
  end

  def handle_event("set_session_id", %{"id" => id}, socket) do
    {:ok, state} = GameObjects.Game.get_state()

    if state != %{} do
      IO.puts("Ongoing game")
    end

    {:noreply, assign(socket, session_id: id)}
  end

  # Join Game Handle Event
  @impl true
  def handle_event("join_game", _params, socket) do
    session_id = socket.assigns.session_id

    case GameObjects.Game.join_game(session_id) do
      {:ok, game} ->
        # Update the LiveView assigns with the new game state
        {:noreply, assign(socket, message: "Joined", game: game)}

      {:err, message} ->
        {:noreply, assign(socket, message: message)}
    end
  end

  # Leave Game Handle Event
  @impl true
  def handle_event("leave_game", _params, socket) do
    session_id = socket.assigns.session_id

    case GenServer.call(GameObjects.Game, {:leave_game, session_id}) do
      {:ok, "No players, Game deleted.", _empty_state} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "You left the game. The game was deleted because no players are left."
         )}

      {:ok, updated_game} ->
        {:noreply, assign(socket, message: "You left the game.", game: updated_game)}
    end
  end

  # Start Game Handle Event
  def handle_event("start_game", _params, socket) do
    case GameObjects.Game.start_game() do
      {:ok, updated_game} ->
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("buy_property", _params, socket) do
    session_id = socket.assigns.session_id
    {:ok, current_game} = GameObjects.Game.get_state()
    IO.inspect(current_game, label: "Current Game State")

    current_player = current_game.current_player
    property = Enum.at(current_game.properties, current_player.position)

    case GameObjects.Game.buy_property(session_id, property) do
      {:ok, updated_game} ->
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "player_joined",
          payload: %{game: updated_game, session_id: session_id}
        },
        socket
      ) do
    {:noreply,
     assign(socket,
       message: "New Player Joined: #{session_id}",
       game: updated_game
     )}
  end

  @impl true
  def handle_event("roll_dice", _params, socket) do
    session_id = socket.assigns.session_id

    case GameObjects.Game.roll_dice(session_id) do
      {:ok, dice_result, current_position, current_tile, updated_game} ->
        message = "Landed on #{current_tile.name}"

        {:noreply,
         socket
         |> assign(:game, updated_game)
         |> assign(:message, message)}

      {:err, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("end_turn", %{"session_id" => session_id}, socket) do
    case GameObjects.Game.end_turn(session_id) do
      {:ok, new_state} ->
        {:noreply, assign(socket, :game_state, new_state)}

      {:err, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "turn_ended", payload: updated_state}, socket) do
    roll_condition =
      !(updated_state.current_player.id === socket.assigns.session_id) ||
        updated_state.current_player.rolled

    {:noreply,
     assign(socket,
       game: updated_state
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "game_update", payload: updated_game},
        socket
      ) do
    if updated_game.current_player do
      roll_condition =
        !(updated_game.current_player.id === socket.assigns.session_id) ||
          updated_game.current_player.rolled

      {:noreply,
       assign(socket,
         message: "New Game Created",
         game: updated_game
       )}
    else
      {:noreply, assign(socket, message: "New Game Created", game: updated_game)}
    end
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "game_deleted", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "Game Deleted", game: updated_game)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "unowned_property", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "Landed on unowned property.", game: updated_game)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "property_bought", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "Bought a property.", game: updated_game)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "card_played", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "Played get out of jail card.", game: updated_game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 style="font-size:50px">Backend Integration</h1>

    <div id="session-id-hook" phx-hook="SessionId"></div>

    <h2>Session ID: {@session_id}</h2>
    <hr style="margin-bottom: 30px; margin-top: 30px;" \ />
    <h2 style="font-size: 40px">Lobby actions</h2>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
      <button
        phx-click="join_game"
        disabled={is_nil(@session_id)}
        style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@session_id), do: "#aaa", else: "#43A047"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@session_id), do: "not-allowed", else: "pointer"};"
        }
      >
        Join Game
      </button>

      <button
        phx-click="leave_game"
        disabled={is_nil(@game) || !is_nil(@game.current_player)}
        style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || not is_nil(@game.current_player), do: "#aaa", else: "#E53935"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || not is_nil(@game.current_player), do: "not-allowed", else: "pointer"};"
        }
      >
        Leave Game
      </button>

      <button
        phx-click="start_game"
        disabled={is_nil(@game) || !is_nil(@game.current_player)}
        style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || not is_nil(@game.current_player), do: "#aaa", else: "#FC8C00"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || not is_nil(@game.current_player), do: "not-allowed", else: "pointer"};"
        }
      >
        Start Game
      </button>
    </div>
    <hr style="margin-bottom: 30px; margin-top: 30px;" />
    <%= if @game do %>
      <h1 style="font-size: 40px">Simulated Lobby - Player List:</h1>

      <ul>
        <%= for player <- @game.players do %>
          <li>
            <strong>
              {player.name} - Sprite: {player.sprite_id}
              <%= if player.id == @session_id do %>
                ⬅️ <span> Current Session </span>
              <% end %>
            </strong>
          </li>
          Session ID: {player.id} <br /> <hr />
          <div style="margin-bottom: 20px; display: flex; gap:100px">
            <div>
              Position: {player.position} <br /> Money: {player.money} <br />
            </div>

            <div>
              Double Count: {player.turns_taken} <br /> In Jail: {player.in_jail}
            </div>
          </div>
        <% end %>
      </ul>

      <%= if @game.current_player do %>
        <hr \ />
        <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
          <!-- Roll Dice -->
          <button
            phx-click="roll_dice"
            disabled={@button_states.roll_dice}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.roll_dice, do: "#aaa", else: "#1E88E5"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.roll_dice, do: "not-allowed", else: "pointer"};"
        }
          >
            Roll Dice
          </button>

    <!-- Buy Properties -->
          <button
            phx-click="buy_property"
            disabled={@button_states.buy_property}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.buy_property, do: "#aaa", else: "#F4511E"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.buy_property, do: "not-allowed", else: "pointer"};"
        }
          >
            Buy Properties
          </button>

    <!-- Upgrade -->
          <button
            phx-click="upgrade"
            disabled={@button_states.upgrade}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.upgrade, do: "#aaa", else: "#6D4C41"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.upgrade, do: "not-allowed", else: "pointer"};"
        }
          >
            Upgrade
          </button>

    <!-- Downgrade -->
          <button
            phx-click="downgrade"
            disabled={@button_states.downgrade}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.downgrade, do: "#aaa", else: "#8E24AA"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.downgrade, do: "not-allowed", else: "pointer"};"
        }
          >
            Downgrade
          </button>

    <!-- End Turn -->
          <button
            phx-click="end_turn"
            phx-value-session_id={@session_id}
            disabled={@button_states.end_turn}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.end_turn, do: "#aaa", else: "#546E7A"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.end_turn, do: "not-allowed", else: "pointer"};"
        }
          >
            End Turn
          </button>

    <!-- Leave Game -->
          <button
            phx-click="leave_game"
            disabled={@button_states.leave_game}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if @button_states.leave_game, do: "#aaa", else: "#871C1C"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.leave_game, do: "not-allowed", else: "pointer"};"
        }
          >
            Leave Game
          </button>
        </div>
        <hr \ />
        <h2 style="font-size: 30px;">Turn: {@game.turn}</h2>

        <h4 style="font-size: 20px;">Players:</h4>

        <h4 style="font-size: 20px;">Current Player:</h4>

        <p>
          ID: {@game.current_player.id},
          ${@game.current_player.money},
          Position: {@game.current_player.position}
        </p>

        <h4 style="font-size: 20px;">Properties:</h4>

        <ul>
          <%= for prop <- @game.properties do %>
            <li>
              {prop.name} - {prop.type} - Cost: ${prop.buy_cost},
              Rent: {inspect(prop.rent_cost)},
              Owner: {if prop.owner, do: inspect(prop.owner), else: "None"}
            </li>
          <% end %>
        </ul>

        <h4 style="font-size: 20px;">Deck:</h4>

        <ul>
          <%= for card <- @game.deck || [] do %>
            <li>
              {card.name} - {card.type} - {format_effect(card.effect)}
            </li>
          <% end %>
        </ul>
      <% end %>
    <% end %>
    """
  end

  defp format_effect({:pay, amount}), do: "Pay $#{amount}"
  defp format_effect({:move, steps}), do: "Move #{steps} steps"
  defp format_effect(other), do: inspect(other)

  defp draw_card_and_update(type, socket) do
    game = socket.assigns.game

    case GameObjects.Deck.draw_card(game.deck || [], type) do
      {:ok, drawn_card} ->
        {:noreply,
         assign(socket,
           game: game,
           message: "Drew #{type} card: #{drawn_card.name}",
           active_card: drawn_card
         )}

      {:error, reason} ->
        {:noreply, assign(socket, :message, "Card draw failed: #{reason}")}
    end
  end
end
