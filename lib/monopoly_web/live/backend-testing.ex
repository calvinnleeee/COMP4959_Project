defmodule MonopolyWeb.BackendTestingLive do
  require Logger
  use MonopolyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, message: nil, game: nil, player_id: nil, active_card: nil)}
  end

  def handle_event("join_game", _params, socket) do
    GameObjects.Game.delete_game()
    session_id = socket.id || UUID.uuid4()
    dummy_id = "dummy_player"

    with {:ok, _game1} <- GameObjects.Game.join_game(session_id),
         {:ok, game} <- GameObjects.Game.join_game(dummy_id) do
      {:noreply,
       assign(socket, message: "Two players joined the game.", game: game, player_id: session_id)}
    else
      {:err, reason} ->
        {:noreply, assign(socket, message: "Join failed: #{reason}")}
    end
  end

  def handle_event("leave_game", _params, socket) do
    case GameObjects.Game.leave_game(socket.assigns.player_id) do
      {:ok, updated_game} ->
        {:noreply,
         assign(socket,
           message: "Player left the game.",
           game: updated_game
         )}

      {:err, reason} ->
        {:noreply, assign(socket, :message, "Leave failed: #{reason}")}
    end
  end

  def handle_event("start_game", _params, socket) do
    case GameObjects.Game.start_game() do
      {:ok, updated_game} ->
        {:noreply,
         assign(socket,
           message: "Game started.",
           game: updated_game
         )}

      {:err, reason} ->
        {:noreply,
         assign(socket,
           message: "Start game failed: #{reason}"
         )}
    end
  end

  # Listend and handle the event when the current player ends their turn
  def handle_event("end_turn", _params, socket) do
    case GameObjects.Game.end_turn(socket.assigns.player_id) do
      {:ok, updated_game_state} ->
        Logger.info("Ended player turn,")
        # TODO: What else needs to go here?? Are these noreplies even correct?
        {:noreply, assign(socket, :message, "Turn ended.")}

      {:err, reason} ->
        Logger.error("Error ending turn: #{reason}")
        {:noreply, assign(socket, :message, "Couldn't end turn due to #{reason}")}
    end
  end

  def handle_event("roll_dice", _params, socket) do
    roll = Enum.random(1..6)
    IO.puts("Rolled a #{roll}")
    {:noreply, assign(socket, :message, "Dice rolled: #{roll}")}
  end

  def handle_event("pay_bank", _params, socket) do
    IO.puts("Paid bank.")
    {:noreply, assign(socket, :message, "Paid bank.")}
  end

  def handle_event("pay_rent", _params, socket) do
    IO.puts("Paid rent.")
    {:noreply, assign(socket, :message, "Paid rent.")}
  end

  def handle_event("build_house", _params, socket) do
    IO.puts("Built a house.")
    {:noreply, assign(socket, :message, "Built a house.")}
  end

  def handle_event("purchase", _params, socket) do
    IO.puts("Purchased property.")
    {:noreply, assign(socket, :message, "Purchased property.")}
  end

  def handle_event("sell_house", _params, socket) do
    IO.puts("Sold a house.")
    {:noreply, assign(socket, :message, "Sold a house.")}
  end

  def handle_event("draw_community_card", _params, socket) do
    draw_card_and_update("community", socket)
  end

  def handle_event("draw_chance_card", _params, socket) do
    draw_card_and_update("chance", socket)
  end

  def handle_event("store_card", _params, socket) do
    game = socket.assigns.game
    player_id = socket.assigns.player_id
    active_card = socket.assigns.active_card

    with player when not is_nil(player) <- Enum.find(game.players, &(&1.id == player_id)),
         card_from_deck when not is_nil(card_from_deck) <-
           Enum.find(game.deck, &(&1.id == active_card.id)) do
      owned_card = GameObjects.Card.mark_as_owned(card_from_deck)

      updated_player = %{
        player
        | cards: [owned_card | player.cards]
      }

      updated_players =
        Enum.map(game.players, fn
          p when p.id == player_id -> updated_player
          p -> p
        end)

      updated_deck = GameObjects.Deck.update_deck(game.deck, owned_card)

      updated_game = %{
        game
        | players: updated_players,
          deck: updated_deck
      }

      {:noreply,
       assign(socket,
         game: updated_game,
         message: "Stored card: #{owned_card.name}",
         active_card: nil
       )}
    else
      nil ->
        {:noreply, assign(socket, :message, "Failed to store card: player or card not found.")}
    end
  end

  def handle_event("use_stored_card", _params, socket) do
    game = socket.assigns.game
    player_id = socket.assigns.player_id

    case Enum.find(game.players, &(&1.id == player_id)) do
      nil ->
        {:noreply, assign(socket, :message, "Player not found.")}

      %{cards: []} ->
        {:noreply, assign(socket, :message, "No cards to use.")}

      player ->
        [card | remaining_cards] = player.cards
        updated_player = GameObjects.Card.apply_effect(card, %{player | cards: remaining_cards})

        updated_players =
          Enum.map(game.players, fn
            p when p.id == player_id -> updated_player
            p -> p
          end)

        updated_game = %{game | players: updated_players}

        {:noreply,
         assign(socket,
           game: updated_game,
           message: "Used card: #{card.name}"
         )}
    end
  end

  def handle_event("use_card", _params, socket) do
    game = socket.assigns.game
    player_id = socket.assigns.player_id
    card = socket.assigns.active_card

    case Enum.find(game.players, &(&1.id == player_id)) do
      nil ->
        {:noreply, assign(socket, :message, "Player not found.")}

      player ->
        updated_player = GameObjects.Card.apply_effect(card, player)

        updated_players =
          Enum.map(game.players, fn
            p when p.id == player_id -> updated_player
            p -> p
          end)

        updated_game = %{game | players: updated_players}

        {:noreply,
         assign(socket,
           game: updated_game,
           message: "Used card: #{card.name}",
           active_card: nil
         )}
    end
  end

  def render(assigns) do
    ~H"""
    <h1 style="font-size:50px">Backend Integration Testing</h1>

    <!-- Game Setup -->
    <h3 style="text-align: center; margin-top: 10px; font-size: 24px; color: #1E88E5;">Game Setup</h3>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
      <button
        phx-click="join_game"
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

    <!-- Turn Actions -->
    <h3 style="text-align: center; margin-top: 10px; font-size: 24px; color: #8E24AA;">
      Turn Actions
    </h3>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
      <button style="padding: 10px 20px; background-color: #8E24AA; color: white; border: none; border-radius: 5px; cursor: pointer;">
        End Turn
      </button>

      <button style="padding: 10px 20px; background-color: #3949AB; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Roll Dice
      </button>
    </div>

    <!-- Payment Actions -->
    <h3 style="text-align: center; margin-top: 10px; font-size: 24px; color: #D81B60;">
      Payment Actions
    </h3>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
      <button style="padding: 10px 20px; background-color: #6D4C41; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Pay Bank
      </button>

      <button style="padding: 10px 20px; background-color: #D81B60; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Pay Rent
      </button>
    </div>

    <!-- Property Actions -->
    <h3 style="text-align: center; margin-top: 10px; font-size: 24px; color: #00ACC1;">
      Property Actions
    </h3>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px;">
      <button style="padding: 10px 20px; background-color: #00ACC1; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Build House
      </button>

      <button style="padding: 10px 20px; background-color: #7CB342; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Purchase
      </button>

      <button style="padding: 10px 20px; background-color: #5D4037; color: white; border: none; border-radius: 5px; cursor: pointer;">
        Sell House
      </button>
    </div>

    <!-- Card Actions -->
    <h3 style="text-align: center; margin-top: 10px; font-size: 24px; color: #26C6DA;">
      Card Actions
    </h3>

    <div style="display: flex; gap: 10px; justify-content: center; margin-top: 10px; margin-bottom: 40px;">
      <button
        phx-click="draw_community_card"
        disabled={is_nil(@game)}
        style={
    "padding: 10px 20px; background-color: #26C6DA; color: white; border: none; border-radius: 5px; " <>
    "cursor: #{if is_nil(@game), do: "not-allowed", else: "pointer"};"
    }
      >
        Draw Community Card
      </button>

      <button
        phx-click="draw_chance_card"
        disabled={is_nil(@game)}
        style={
    "padding: 10px 20px; background-color: rgb(38, 218, 98); color: white; border: none; border-radius: 5px; " <>
    "cursor: #{if is_nil(@game), do: "not-allowed", else: "pointer"};"
    }
      >
        Draw Chance Card
      </button>

      <button
        phx-click="store_card"
        disabled={is_nil(@active_card)}
        style={
    "padding: 10px 20px; background-color: rgb(191, 218, 38); color: white; border: none; border-radius: 5px; " <>
    "cursor: #{if is_nil(@active_card), do: "not-allowed", else: "pointer"};"
    }
      >
        Store Card
      </button>

      <button
        phx-click="use_stored_card"
        disabled={is_nil(@game)}
        style={
    "padding: 10px 20px; background-color: rgb(218, 119, 38); color: white; border: none; border-radius: 5px; " <>
    "cursor: #{if is_nil(@game), do: "not-allowed", else: "pointer"};"
    }
      >
        Use Stored Card
      </button>

      <button
        phx-click="use_card"
        disabled={is_nil(@active_card)}
        style={
    "padding: 10px 20px; background-color: rgb(218, 170, 38); color: white; border: none; border-radius: 5px; " <>
    "cursor: #{if is_nil(@active_card), do: "not-allowed", else: "pointer"};"
    }
      >
        Use Card Effect
      </button>
    </div>

    <p><strong>Simulation:</strong> {@message || "No simulation triggerd yet."}</p>
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
