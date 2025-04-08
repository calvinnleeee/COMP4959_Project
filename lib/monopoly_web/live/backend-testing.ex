defmodule MonopolyWeb.BackendTestingLive do
  require Logger
  use MonopolyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")

    tile_layout = build_tile_layout()

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
       local_message: nil,
       global_message: nil,
       game: nil,
       session_id: nil,
       player_name: nil,
       button_states: button_states,
       dice_roll: 0,
       tile_layout: tile_layout
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
        # Find the player's name from the game state
        player_name =
          game.players
          |> Enum.find(fn player -> player.id == session_id end)
          |> Map.get(:name, "Unknown")

        {:noreply,
         assign(socket,
           local_message: "#{player_name} Joined",
           game: game,
           player_name: player_name
         )}

      {:err, message} ->
        {:noreply, assign(socket, local_message: message)}
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
         |> assign(
           :local_message,
           "You left the game. The game was deleted because no players are left."
         )}

      {:ok, updated_game} ->
        {:noreply, assign(socket, local_message: "You left the game.", game: updated_game)}
    end
  end

  # Start Game Handle Event
  def handle_event("start_game", _params, socket) do
    case GameObjects.Game.start_game() do
      {:ok, updated_game} ->
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
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
        IO.inspect(updated_game.current_player.properties, label: "Current Player Properties")
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
    end
  end

  @impl true
  def handle_event("upgrade-property", _params, socket) do
    session_id = socket.assigns.session_id
    {:ok, current_game} = GameObjects.Game.get_state()
    IO.inspect(current_game, label: "Current Game State")

    current_player = current_game.current_player
    property = Enum.at(current_game.properties, current_player.position)

    case GameObjects.Game.upgrade_property(session_id, property) do
      {:ok, updated_game} ->
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
    end
  end

  @impl true
  def handle_event("downgrade", %{"id" => prop_id_str}, socket) do
    session_id = socket.assigns.session_id
    prop_id = String.to_integer(prop_id_str)
    {:ok, current_game} = GameObjects.Game.get_state()
    property = Enum.at(current_game.properties, prop_id)

    case GameObjects.Game.downgrade_property(session_id, property) do
      {:ok, updated_game} ->
        {:noreply, assign(socket, game: updated_game)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
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
       global_message: "New Player Joined.",
       game: updated_game
     )}
  end

  @impl true
  def handle_event("roll_dice", _params, socket) do
    session_id = socket.assigns.session_id

    case GameObjects.Game.roll_dice(session_id) do
      {:ok, dice_result, current_position, current_tile, updated_game} ->
        message =
          case updated_game.active_card do
            nil -> "Landed on #{current_tile.name}"
            card -> "GOT 🃏 #{card.name}. #{format_effect(card.effect)}"
          end

        {:noreply,
         socket
         |> assign(:game, updated_game)
         |> assign(:local_message, message)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
    end
  end

  @impl true
  def handle_event("end_turn", %{"session_id" => session_id}, socket) do
    case GameObjects.Game.end_turn(session_id) do
      {:ok, new_state} ->
        {:noreply, assign(socket, :game_state, new_state)}

      {:err, reason} ->
        {:noreply, assign(socket, local_message: reason)}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "turn_ended", payload: updated_state}, socket) do
    {:noreply,
     assign(socket,
       game: updated_state,
       global_message: "Waiting for #{updated_state.current_player.name}'s action..."
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "updated_state", payload: updated_state},
        socket
      ) do
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
      {:noreply,
       assign(socket,
         game: updated_game
       )}
    else
      {:noreply, assign(socket, game: updated_game)}
    end
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "game_deleted", payload: updated_game},
        socket
      ) do
    {:noreply, assign(socket, game: updated_game)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "unowned_property", payload: updated_game},
        socket
      ) do
    {:noreply,
     assign(socket,
       global_message:
         "#{updated_game.current_player.name} landed on an unowned #{get_location(updated_game, updated_game.current_player.position).name}.",
       game: updated_game
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "property_bought", payload: updated_game},
        socket
      ) do
    {:noreply,
     assign(socket,
       global_message:
         "#{updated_game.current_player.name} bought #{get_location(updated_game, updated_game.current_player.position).name}.",
       game: updated_game
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "property_sold", payload: updated_game},
        socket
      ) do
    {:noreply,
     assign(socket,
       global_message: "#{updated_game.current_player.name} sold a property.",
       game: updated_game
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "property_downgraded", payload: updated_game},
        socket
      ) do
    {:noreply,
     assign(socket,
       global_message: "#{updated_game.current_player.name} downgraded a property.",
       game: updated_game
     )}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "card_played", payload: updated_game},
        socket
      ) do
    {:noreply,
     assign(socket,
       global_message: "#{updated_game.current_player.name} played get out of jail card.",
       game: updated_game
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="session-id-hook" phx-hook="SessionId"></div>

    <div style="display: flex; height: 800px; box-sizing: border-box;width:1800px">
      <!-- Left Side: Board Image -->
      <div style="flex: 3; display: flex; align-items: center; justify-content: center; overflow: hidden; position: relative;">
        <%= if !@game || (@game && !@game.current_player) do %>
          <img
            src={~p"/images/game_logo.png"}
            alt="Game Logo"
            style="height: 80%; width: auto; max-height: 80vh;"
          />
        <% else %>
          <div style="position: relative; display: inline-block;">
            <img
              src={~p"/images/board.png"}
              alt="Game Board"
              style="height: 100%; width: auto; max-height: 83vh;"
            />
            <!-- Sprite -->
            <%= if @game && @game.current_player do %>
              <%= for player <- @game.players do %>
                <% tile = @tile_layout[player.position] %> <% col = rem(player.sprite_id, 2) * 35 %>
                <% row = div(player.sprite_id, 2) * 25 %>
                <img
                  src={"/images/#{player.sprite_id}.png"}
                  alt={"#{player.name}"}
                  style={"height: 40px; width: auto; position: absolute;
            top: #{tile.y + row}px;
            left: #{tile.x + col}px;
            transform: translate(-50%, -50%);"}
                />
              <% end %>
            <% end %>
          </div>
          <!-- image -->
          <div style="
    position: absolute;
    top: 50%;
    left: 50%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    transform: translate(-50%, -50%);
    color: white;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: white;
    max-width: 40%;
    text-shadow: 0 0 10px rgba(11, 255, 64, 0.94), 0 0 20px rgba(255, 255, 255, 0.3);
    margin-bottom: 30px;">
            <div style="font-size: 3rem;">Turn {@game.turn}</div>

            <div style="font-size: 2rem; text-align: center">{@global_message}</div>
          </div>
        <% end %>
      </div>

    <!-- Right Side: Existing UI -->
      <div style={
    "flex: 1; " <>
    "display:flex; " <>
    "padding: 50px; " <>
    "overflow-y: hidden; " <>
    "border: 1px solid rgba(255, 255, 255, 0.3); " <>
    "background: rgba(255, 255, 255, 0.1); " <>
    "backdrop-filter: blur(10px); " <>
    "-webkit-backdrop-filter: blur(10px); " <>
    "border-radius: 15px; " <>
    "box-shadow: 0 4px 30px rgba(0, 0, 0, 0.5); " <>
    "color: white; " <>
    if !@game || (!is_nil(@game) && is_nil(@game.current_player)) do
    "justify-content: center; align-items: center;"
    else
    "flex-direction: column;"
    end
    }>
        <%= if !@game || (@game && !@game.current_player) do %>
          <div>
            <h2 style="font-size: 3rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px rgba(11, 255, 64, 0.94), 0 0 20px rgba(255, 255, 255, 0.3);
              margin-bottom: 30px;">
              Vancouver Housing Market
            </h2>

            <div style="display: flex; gap: 10px; justify-content: center; flex-direction: column; margin-top: 10px; gap: 40px">
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
            </div>
          </div>
        <% end %>

        <%= if @game && @game.current_player do %>
          <%= if @game.winner do %>
            <h1>Winner: {@game.winner.name}</h1>
          <% else %>
            <%= if @game.current_player.id == @session_id do %>
              <div style="text-align: right">
                <span style="font-size: 3rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px rgba(11, 255, 64, 0.94), 0 0 20px rgba(255, 255, 255, 0.3);
              margin-bottom: 30px">
                  your Turn
                </span>
              </div>
            <% else %>
              <div style="text-align: right">
                <span style="font-size: 3rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px rgba(255, 11, 11, 0.94), 0 0 20px rgba(255, 255, 255, 0.3);
              margin-bottom: 30px">
                  Not your Turn
                </span>
              </div>
            <% end %>

            <%= if @game.players do %>
              <span style={"
              font-size: 2rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px #{if @game.current_player.id == @session_id, do: "rgba(11, 255, 64, 0.94)", else: "rgba(255, 11, 11, 0.94)"},
                          0 0 20px rgba(255, 255, 255, 0.3);"}>
                {@player_name}
              </span>

              <div style={"
              font-size: 1.5rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              margin-top: 20px;
              margin-bottom: 20px;
              text-shadow: 0 0 10px #{if @game.current_player.id == @session_id, do: "rgba(11, 255, 64, 0.94)", else: "rgba(255, 11, 11, 0.94)"},
                          0 0 20px rgba(255, 255, 255, 0.3);"}>
                <div style="display: flex; flex-direction: row; justify-content: space-between;">
                  <div style="flex: 3">
                    📍 {String.upcase(
                      get_location(@game, get_player(@game, @session_id).position).name
                    )}
                    <br /><span style="opacity: 0">📍 </span><span>(POSITION {get_player(
                  @game,
                  @session_id
                ).position}) </span>
                  </div>

                  <div>
                    <% location = get_location(@game, get_player(@game, @session_id).position)
                    buy_cost = location.buy_cost
                    owner = location.owner %>
                    <%= if owner == nil and buy_cost !== nil do %>
                      <button
                        phx-click="buy_property"
                        disabled={
                          get_location(@game, get_player(@game, @session_id).position).owner != nil
                        }
                        style={
      "flex: 1; " <>
      "padding: 10px 20px; " <>
      "background-color: #{if get_location(@game, get_player(@game, @session_id).position).owner != nil, do: "#aaa", else: "rgba(15, 67, 102, 0.94)"}; " <>
      "color: white; border: none; border-radius: 5px; " <>
      "cursor: #{if get_location(@game, get_player(@game, @session_id).position).owner != nil, do: "not-allowed", else: "pointer"};"
    }
                      >
                        $ {buy_cost}
                      </button>
                    <% end %>
                  </div>
                </div>

                <div style="display: flex; justify-content: space-between; margin-top: 20px">
                  <span>💰 {format_money(get_player(@game, @session_id).money)}</span>
                  <span>🃏 {length(get_player(@game, @session_id).cards)}</span>
                  <span>
                    ❤️ {cond do
                      !get_player(@game, @session_id).active -> "GAME OVER"
                      get_player(@game, @session_id).in_jail -> "IN JAIL"
                      true -> "ALIVE"
                    end}
                  </span>
                </div>
              </div>

              <div style="display: flex; gap: 20px; width: 100%; margin-bottom: 50px; font-size: 1.5rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;">
                <button
                  phx-click="roll_dice"
                  disabled={@button_states.roll_dice}
                  style={
      "flex: 1; padding: 10px 20px; " <>
      "background-color: #{if @button_states.roll_dice, do: "#aaa", else: "rgba(15, 102, 34, 0.94)"}; " <>
      "color: white; border: none; border-radius: 5px; " <>
      "cursor: #{if @button_states.roll_dice, do: "not-allowed", else: "pointer"};"
    }
                >
                  Roll Dice
                </button>

                <button
                  phx-click="end_turn"
                  phx-value-session_id={@session_id}
                  disabled={@button_states.end_turn}
                  style={
      "flex: 1; padding: 10px 20px; " <>
      "background-color: #{if @button_states.end_turn, do: "#aaa", else: "rgba(102, 25, 15, 0.94)"}; " <>
      "color: white; border: none; border-radius: 5px; " <>
      "cursor: #{if @button_states.end_turn, do: "not-allowed", else: "pointer"};"
    }
                >
                  End Turn
                </button>
              </div>

              <span style={"
              font-size: 2rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px #{if @game.current_player.id == @session_id, do: "rgba(11, 255, 64, 0.94)", else: "rgba(255, 11, 11, 0.94)"},
                          0 0 20px rgba(255, 255, 255, 0.3);"}>
                PROPERTIES ({length(get_player(@game, @session_id).properties)})
              </span>

              <span style="
              font-size: 1rem;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 2px;
              color: white;
              text-shadow: 0 0 10px rgba(255, 11, 11, 0.94),
                          0 0 20px rgba(255, 255, 255, 0.3); margin-bottom: 20px">
                CLICK TO SELL / DOWNGRADE
              </span>

              <div style="display: flex; flex-direction: column; gap: 20px; width: 100%; max-width: 600px; margin: auto; margin-top: 20px;">
                <!-- Row 2: Upgrade & Downgrade -->
                <div style="display: flex; gap: 20px;">
                  <button
                    phx-click="upgrade-property"
                    disabled={@button_states.upgrade}
                    style={
        "flex: 1; padding: 10px 20px; " <>
        "background-color: #{if @button_states.upgrade, do: "#aaa", else: "rgba(15, 102, 34, 0.94)"}; " <>
        "color: white; border: none; border-radius: 5px; " <>
        "cursor: #{if @button_states.upgrade, do: "not-allowed", else: "pointer"};"
      }
                  >
                    Upgrade
                  </button>
                </div>

                <div style={"
    max-height: 60%;
    overflow-y: auto;
    scrollbar-width: none; /* Firefox */
    -ms-overflow-style: none; /* IE and Edge */
    font-size: 1rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: white;
    margin-top: 10px;
    text-shadow: 0 0 10px #{if @game.current_player.id == @session_id, do: "rgba(11, 255, 64, 0.94)", else: "rgba(255, 11, 11, 0.94)"},
               0 0 20px rgba(255, 255, 255, 0.3);
    "}>
                  <style>
                    /* Hide scrollbar for WebKit browsers (Chrome, Safari) */
                    div::-webkit-scrollbar {
                      display: none;
                    }
                  </style>

                  <div style="
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    grid-auto-flow: dense;
    gap: 20px;
    width: 100%;
    align-items: start;
    ">
                    <%= for prop <- get_player(@game, @session_id).properties do %>
                      <div
                        phx-click="downgrade"
                        phx-value-id={prop.id}
                        style="
                        padding: 10px;
                        background-color: rgba(255, 255, 255, 0.1);
                        border-radius: 10px;
                        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
                        color: white;
                        text-shadow: 0 0 5px rgba(0, 255, 0, 0.5);
                        font-size: 1rem;
                        font-weight: 600;
                        word-break: break-word;
                        height: 100%;
                        cursor: pointer;
                      "
                      >
                        🧱 {prop.name}<br /> ({prop.type})
                      </div>
                    <% end %>
                  </div>

                  <%= if length(get_player(@game, @session_id).properties) === 0 do %>
                    <span style="font-size: 1.5rem;"> IT’S A BUYER’S MARKET! </span> <br />
                    <span style="font-size: 1.5rem;"> GO SHOPPING! </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>

          <div style={"margin-top: auto; padding-top: 20px; font-size: 1.2rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: white;
    text-shadow: 0 0 10px #{if @game.current_player.id == @session_id, do: "rgba(255, 11, 11, 0.94)", else: "rgba(255, 11, 11, 0.94)"},
               0 0 20px rgba(255, 255, 255, 0.3);
    "}>
            <%= if @local_message !== nil do %>
              {@local_message}
            <% else %>
              NO MESSAGE YET
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_effect({:pay, amount}), do: "Pay $#{amount}"
  defp format_effect({:earn, amount}), do: "Earn $#{amount}"
  defp format_effect(other), do: inspect(other)

  defp format_money(amount) when is_integer(amount) do
    int_part = Integer.to_string(amount)

    with_commas =
      int_part
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.reverse()
      |> Enum.intersperse([","])
      |> List.flatten()
      |> Enum.join()

    "$" <> with_commas
  end

  defp get_player(game, session_id) do
    game.players
    |> Enum.find(fn player -> player.id == session_id end)
  end

  defp get_location(game, location) do
    game.properties
    |> Enum.find(fn property -> property.id == location end)
  end

  defp build_tile_layout do
    board_size = 793
    corner_size = 79
    step = 67
    step2 = 60

    # Bottom row (0 to 9) - right to left
    bottom_row =
      for i <- 0..10 do
        x = board_size - corner_size - i * step
        {i, %{x: x, y: board_size - corner_size}}
      end

    # Left column (10 to 19) - bottom to top
    left_column =
      for i <- 2..9 do
        y = board_size - corner_size - i * step2
        {i + 9, %{x: 0, y: y}}
      end

    # Top row (20 to 29) - left to right
    top_row =
      for i <- 0..10 do
        x = corner_size + i * step
        {i + 20, %{x: x, y: 0}}
      end

    # Right column (30 to 39) - top to bottom
    right_column =
      for i <- 2..9 do
        y = corner_size + i * step2
        {i + 29, %{x: board_size - corner_size, y: y}}
      end

    Enum.into(bottom_row ++ left_column ++ top_row ++ right_column, %{})
  end
end
