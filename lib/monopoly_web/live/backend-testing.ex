defmodule MonopolyWeb.BackendTestingLive do
  require Logger
  use MonopolyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Monopoly.PubSub, "game:lobby")
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

    case GameObjects.Game.join_game(session_id) do
      {:ok, game} ->
        # Update the LiveView assigns with the new game state
        {:noreply, assign(socket, message: "Joined", game: game)}

      {:err, message} ->
        {:noreply, assign(socket, message: message)}
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
        %Phoenix.Socket.Broadcast{event: "new_game", payload: %{game: updated_game}},
        socket
      ) do
    {:noreply, assign(socket, message: "New Game Created", game: updated_game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 style="font-size:50px">Backend Integration</h1>

    <div id="session-id-hook" phx-hook="SessionId"></div>
    <h2>Player: {@session_id}</h2>
     <hr \ />
    <h2>Action available</h2>

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
        disabled={is_nil(@game)}
        style={
        "padding: 10px 20px; " <>
        "background-color: #{if is_nil(@game), do: "#aaa", else: "#E53935"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if is_nil(@game), do: "not-allowed", else: "pointer"};"
        }
      >
        Leave Game
      </button>

      <button
        phx-click="start_game"
        style="padding: 10px 20px; background-color: #FB8C00; color: white; border: none; border-radius: 5px; cursor: pointer;"
      >
        Start Game
      </button>
    </div>
     <hr \ />
    <p><strong>Game:</strong> {@message || "Nothing yet."}</p>
     <hr style="margin-bottom: 10px;" />
    <%= if @game do %>
      <h3 style="margin-top: 30px; font-size: 24px;">Game State</h3>

      <p><strong>Turn:</strong> {@game.turn}</p>

      <h4 style="font-size: 20px;">Players:</h4>

      <ul>
        <%= for player <- @game.players do %>
          <li>
            ID: {player.id},
            ${player.money},
            Position: {player.position},
            In Jail: {player.in_jail},
            Cards: {Enum.map(player.cards, & &1.name) |> Enum.join(", ")}
          </li>
        <% end %>
      </ul>

      <h4 style="font-size: 20px;">Current Player:</h4>

      <%= if @game.current_player do %>
        <p>
          ID: {@game.current_player.id},
          ${@game.current_player.money},
          Position: {@game.current_player.position}
        </p>
      <% else %>
        <p>None yet</p>
      <% end %>

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
