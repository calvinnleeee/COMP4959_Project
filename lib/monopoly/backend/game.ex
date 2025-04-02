defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which contains vital data and methods to run it.

  `players` is a list of GameObjects.Player structs.
  """
  require Logger
  use GenServer
  alias GameObjects.Game
  alias GameObjects.{Deck, Player, Property, Dice}

  # CONSTANTS HERE
  # ETS table defined in application.ex

  @game_store Game.Store
  @max_player 6
  @jail_position 11
  @go_to_jail_position 31
  @income_tax_position 5
  @parking_tax_position 21
  @luxury_tax_position 39
  @go_bonus 200
  @jail_fee 50
  @luxury_tax_fee 75
  # we will keep income tax as a static 200 because it is easy.
  @income_tax_fee 200
  # we will keep parking tax as a static 100 because it is easy.
  @parking_tax_fee 200

  # Game struct definition
  # properties and players are both lists of their respective structs
  defstruct [:state, :players, :properties, :deck, :current_player, :active_card, :turn]

  # ---- Public API functions ----

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initialize a new Player instance and add it to the Game.
  # Assumes the player's client will have a PID and Web socket.
  def join_game(session_id) do
    GenServer.call(__MODULE__, {:join_game, session_id})
  end

  # Remove the player from the game.
  def leave_game(session_id) do
    GenServer.call(__MODULE__, {:leave_game, session_id})
  end

  # Start the main game loop.
  def start_game() do
    GenServer.call(__MODULE__, :start_game)
  end

  def delete_game() do
    GenServer.call(__MODULE__, :delete_game)
  end

  # Return the Game's current state.
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # Play a card.
  def play_card(session_id) do
    GenServer.call(__MODULE__, {:play_card, session_id})
  end

  def end_turn(session_id) do
    GenServer.call(__MODULE__, {:end_turn, session_id})
  end

  def roll_dice(session_id) do
    GenServer.call(__MODULE__, {:roll_dice, session_id})
  end

  # ---- Private functions & GenServer Callbacks ----

  @impl true
  def init(_) do
    unless :ets.whereis(@game_store) != :undefined do
      :ets.new(@game_store, [:named_table, :public, :set])
    end

    {:ok, %{}}
  end

  # ---- PLayer related handles ---- #

  # Add a new player to the game , update game state in ETS and broadcast change.
  # If game doesn't exist in ETS, create a new game and add player to it.

  # session_id:  unique identifier for a player (their socket).
  # name: string, the player's chosen gamertag/nickname
  # sprite_id: a unique number to identify the the sprite they've selected.
  @impl true
  def handle_call({:join_game, session_id}, _from, _state) do
    case :ets.lookup(@game_store, :game) do
      # If the game already exists
      [{:game, existing_game}] ->
        if Enum.any?(existing_game.players, fn player -> player.id == session_id end) do
          {:reply, {:ok, existing_game}, existing_game}
        else
          if length(existing_game.players) >= @max_player do
            {:reply, {:err, "Maximum 6 Players"}, existing_game}
          else
            player_count = length(existing_game.players)
            name = "Player #{player_count + 1}"
            sprite_id = player_count
            new_player = GameObjects.Player.new(session_id, name, sprite_id)

            updated_game = update_in(existing_game.players, &[new_player | &1])
            :ets.insert(@game_store, {:game, updated_game})
            MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_game)
            {:reply, {:ok, updated_game}, updated_game}
          end
        end

      # If the game doesn't exist
      [] ->
        name = "Player 1"
        sprite_id = 0
        new_player = GameObjects.Player.new(session_id, name, sprite_id)

        new_game = %__MODULE__{
          players: [new_player],
          properties: [],
          deck: nil,
          current_player: nil,
          active_card: nil,
          turn: 0
        }

        :ets.insert(@game_store, {:game, new_game})
        MonopolyWeb.Endpoint.broadcast("game_state", "game_update", new_game)
        {:reply, {:ok, new_game}, new_game}
    end
  endq

  # Handle dice rolling
  @impl true
  def handle_call({:roll_dice, session_id}, _from, state) do
    case :ets.lookup(@game_store, :game) do
      [{:game, game}] ->
        current_player = game.current_player

        if current_player.id != session_id do
          {:reply, {:err, "Not your turn"}, state}
        else
          {dice_result, current_tile, updated_game} =
            if current_player.in_jail do
              handle_jail_roll(game)
            else
              handle_normal_roll(game)
            end

          current_position = updated_game.current_player.position
          :ets.insert(@game_store, {:game, updated_game})
          MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_game)
          {:reply, {:ok, dice_result, current_position, current_tile, updated_game}, updated_game}
        end

      [] ->
        {:reply, {:err, "No active game"}, state}
    end
  end

  # Handle rolling dice when player is in jail
  defp handle_jail_roll(game) do
    player = game.current_player
    {jail_status, dice, sum} = Dice.jail_roll(player.jail_turns)

    updated_player =
      case jail_status do
        :out_of_jail ->
          player = %{player | in_jail: false, jail_turns: 0, turns_taken: 0}
          move_player(player, sum)

        :failed_to_escape ->
          player = %{player | in_jail: false, jail_turns: 0, turns_taken: 0}
          player = Player.lose_money(player, @jail_fee)
          move_player(player, sum)

        :stay_in_jail ->
          %{player | jail_turns: player.jail_turns + 1}
      end

    current_tile = get_tile(game, updated_player.position)
    updated_game = update_player(game, updated_player)
    {{dice, sum, jail_status}, current_tile, updated_game}
  end

  @doc """
    Handle rollilng the dice for players NOT in Jail.
    Check if the tile the player lands on is a Card (Community or Chance) or a Property.
    Pays rent if property owned by another player, otherwise inform of chance to buy.
  """
  defp handle_normal_roll(game) do
    player = game.current_player
    {dice, sum, is_doubles} = Dice.roll()

    updated_player =
      if is_doubles do
        %{player | turns_taken: player.turns_taken + 1}
      else
        %{player | turns_taken: 0}
      end

    should_go_to_jail = Dice.check_for_jail(updated_player.turns_taken, is_doubles)

    updated_player =
      if should_go_to_jail do
        %{updated_player | in_jail: true, position: @jail_position, turns_taken: 0}
      else
        move_player(updated_player, sum)
      end

    current_tile = get_tile(game, updated_player.position)
    updated_game = update_player(game, updated_player)

    # Checking what the user has landed on.
    updated_game =
      cond do
        current_tile.type in ["community", "chance"] ->
          case Deck.draw_card(updated_game.deck, current_tile.type) do
            {:ok, card} ->
              %{updated_game | active_card: card}

            {:error, _reason} ->
              updated_game
          end

        current_tile.type not in ["community", "chance", "tax", "go", "jail", "go_to_jail"] ->
          # if player lands on a property
          if GameObjects.Property.is_owned(current_tile) do
            # check who owns it
            case GameObjects.Property.get_owner(current_tile) do
              owner.id != player.id ->
                prop_rent = GameObjects.Property.get_current_rent(current_tile)
                # pay rent
                if GameObjects.Player.get_money(player) >= prop_rent do
                  {player_minus_rent, owner_plus_rent} =
                    GameObjects.Player.lose_money(player, owner, prop_rent)

                  # update player and owner
                  updated_players =
                    Enum.map(state.players, fn p ->
                      cond do
                        p.id == player.id -> player_minus_rent
                        p.id == owner.id -> owner_plus_rent
                        true -> p
                      end
                    end)

                  updated_state = %{state | players: updated_players}
                  :ets.insert(@game_store, {:game, updated_state})
                  # MonopolyWeb.Endpoint.broadcast("game_state", "rent_paid", updated_state)
                  {:reply, {:ok, updated_state}, updated_state}
                else
                  # TODO: removed player from game using their session_id, someone with better game flow sense review this pls.
                  leave_game(session_id)
                end

              owner.id == player.id ->
                # TODO: now what? upgrade?

              _ ->
                Logger.error("Huhhhh? Who's the owner?")
            end
          else
            # Property is Not owned, announce that via broadcast
            # Frontend will invoke the purchase flow
            MonopolyWeb.Endpoint.broadcast("game_state", "buy_prop?", updated_game)
          end
      end

    {{dice, sum, is_doubles}, current_tile, updated_game}
  end

  # Move player and handle passing go
  defp move_player(player, steps) do
    old_position = player.position
    updated_player = Player.move(player, steps)
    passed_go = old_position + steps >= 40 && !player.in_jail

    cond do
      updated_player.position == @income_tax_position ->
        updated_player = Player.lose_money(updated_player, @income_tax_fee)

      updated_player.position == @luxury_tax_position ->
        updated_player = Player.lose_money(updated_player, @luxury_tax_fee)

      updated_player.position == @go_to_jail_position ->
        updated_player =
          Player.set_in_jail(updated_player, true) |> Player.set_position(@jail_position)

      updated_player.position == @parking_tax_position ->
        updated_player = Player.lose_money(updated_player, @parking_tax_fee)

      passed_go ->
        updated_player = Player.add_money(updated_player, @go_bonus)

      true ->
        updated_player
    end

    updated_player

    if passed_go,
      do: %{updated_player | money: updated_player.money + @go_bonus},
      else: updated_player
  end

  # Update a player in the game state
  defp update_player(game, updated_player) do
    updated_players =
      Enum.map(game.players, fn player ->
        if player.id == updated_player.id do
          updated_player
        else
          player
        end
      end)

    %{game | players: updated_players, current_player: updated_player}
  end

  # Get tile from properties list by position
  defp get_tile(game, position) do
    Enum.find(game.properties, fn property -> property.id == position end)
  end

  @impl true
  def handle_call({:leave_game, session_id}, _from, state) do
    filtered_players =
      state.players
      |> Enum.reject(fn player -> player.id == session_id end)
      |> Enum.with_index()
      |> Enum.map(fn {player, idx} ->
        %GameObjects.Player{player | name: "Player #{idx + 1}", sprite_id: idx}
      end)

    updated_state = %{state | players: filtered_players}

    cond do
      Enum.empty?(filtered_players) ->
        :ets.delete(@game_store, :game)
        MonopolyWeb.Endpoint.broadcast("game_state", "game_deleted", nil)
        {:reply, {:ok, "No players, Game deleted.", %{}}, %{}}

      true ->
        :ets.insert(@game_store, {:game, updated_state})
        MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_state)
        {:reply, {:ok, updated_state}, updated_state}
    end
  end

  @doc """
    End the current player's turn, but check if the rolled first, if not make them roll.
    Set next player as new current, reste the current player's turn count, and update state.
  """
  @impl true
  def handle_call({:end_turn, session_id}, _from, state) do
    case :ets.lookup(@game_store, {:game, state.current_player}) do
      [] ->
        {:reply, {:err, "No active game found."}, state}

      [{_key, current_player}] ->
        if GameObjects.Player.get_id(current_player) == session_id do
          if current_player.turns_taken > 0 do
            current_player_index =
              Enum.find_index(state.players, fn player ->
                player.id == state.current_player.id
              end)

            # Get next player
            next_player_index = rem(current_player_index + 1, length(state.players))
            next_player = Enum.at(state.players, next_player_index)

            # Reset turns_taken for the current player
            updated_players =
              List.replace_at(state.players, current_player_index, %{
                current_player
                | turns_taken: 0
              })

            # Update statu
            updated_state = %{
              state
              | players: updated_players,
                current_player: next_player,
                turn: state.turn + 1
            }

            :ets.insert(@game_store, {:game, updated_state})
            MonopolyWeb.Endpoint.broadcast("game_state", "turn_ended", updated_state)
            {:reply, {:ok, updated_state}, updated_state}
          else
            {:reply, {:err, "Must roll first"}, state}
          end
        else
          {:reply, {:err, "Invalid session ID"}, state}
        end
    end
  end

  # ---- Game Related handles ---- #

  # Get current game state.
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  # Start the game
  @impl true
  def handle_call(:start_game, _from, state) do
    if length(state.players) > 1 do
      updated_players = put_in(state.current_player, List.first(state.players))
      updated_cards = put_in(updated_players.deck, Deck.init_deck())
      updated_state = put_in(updated_cards.properties, Property.init_property_list())
      :ets.insert(@game_store, {:game, updated_state})
      MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_state)
      {:reply, {:ok, updated_state}, updated_state}
    else
      {:reply, {:err, "Need at least 2 players"}, state}
    end
  end

  # Delete the game
  @impl true
  def handle_call(:delete_game, _from, _state) do
    case :ets.lookup(@game_store, :game) do
      # If game exists, delete it
      [{:game, _game}] ->
        :ets.delete(@game_store, :game)
        {:reply, :ok, %{}}

      # If no game exists
      [] ->
        {:reply, {:err, "No active game to delete!"}, %{}}
    end
  end

  # Play a card
  @impl true
  def handle_call({:play_card, session_id}, _from, state) do
    current_player = state.current_player

    if current_player.id != session_id do
      {:reply, {:err, "Invalid session ID"}, state}
    else
      case state.active_card do
        nil ->
          {:reply, {:err, "No active card to play"}, state}

        card ->
          # Apply effect to the current player and update the players list
          updated_player = GameObjects.Card.apply_effect(card, current_player)

          updated_players =
            Enum.map(state.players, fn player ->
              if player.id == current_player.id, do: updated_player, else: player
            end)

          # Clear the active card
          updated_state = %{
            state
            | players: updated_players,
              current_player: updated_player,
              active_card: nil
          }

          # Broadcast the state change
          MonopolyWeb.Endpoint.broadcast("game_state", "card_played", updated_state)
          {:reply, {:ok, updated_state}, updated_state}
      end
    end
  end

  # Terminate and save state on failure.
  @impl true
  def terminate(_reason, state) do
    :ets.insert(@game_store, {:game, state})
    :ok
  end
end
