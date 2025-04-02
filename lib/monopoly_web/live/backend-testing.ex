defmodule MonopolyWeb.BackendTestingLive do
  require Logger
  use MonopolyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, assign(socket, message: nil, game: nil, session_id: nil)}
  end

  def handle_event("set_session_id", %{"id" => id}, socket) do
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
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "game_update", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "New Game Created", game: updated_game)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "game_deleted", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, message: "Game Deleted", game: updated_game)}
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
        style="padding: 10px 20px; background-color: #43A047; color: white; border: none; border-radius: 5px; cursor: pointer;"
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
          (Session ID: {player.id})
        <% end %>
      </ul>

      <%= if @game.current_player do %>
        <hr \ />
        <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
          <!-- Roll Dice -->
          <button
            phx-click="roll_dice"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#1E88E5"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
        }
          >
            Roll Dice
          </button>

    <!-- Buy Properties -->
          <button
            phx-click="buy_property"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#F4511E"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
        }
          >
            Buy Properties
          </button>

    <!-- Play Cards -->
          <button
            phx-click="play_cards"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#8E24AA"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
        }
          >
            Play Cards
          </button>

    <!-- Upgrade -->
          <button
            phx-click="upgrade"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#6D4C41"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
        }
          >
            Upgrade
          </button>

    <!-- End Turn -->
          <button
            phx-click="end_turn"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#546E7A"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
        }
          >
            End Turn
          </button>

    <!-- Leave Game -->
          <button
            phx-click="leave_game"
            disabled={is_nil(@game) || @game.current_player.id !== @session_id}
            style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "#aaa", else: "#871C1C"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game) || @game.current_player.id !== @session_id, do: "not-allowed", else: "pointer"};"
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
