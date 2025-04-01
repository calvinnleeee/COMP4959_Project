defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which contains vital data and methods to run it.

  `players` is a list of GameObjects.Player structs.
  """
  require Logger
  use GenServer
  alias GameObjects.{Deck, Player, Property, Dice}

  # CONSTANTS HERE
  # ETS table defined in application.ex
  @game_store Game.Store
  @max_player 6
  @jail_position 11
  @go_bonus 200
  @jail_fee 50

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

  def roll_dice(session_id) do
    GenServer.call(__MODULE__, {:roll_dice, session_id})
  end

  # Play a card.
  def play_card(session_id, card_id) do
    GenServer.call(__MODULE__, {:play_card, session_id, card_id})
  end

  # ---- Private functions & GenServer Callbacks ----

  @impl true
  def init(_) do
    unless :ets.whereis(@game_store) != :undefined do
      :ets.new(@game_store, [:named_table, :public, :set])
    end

    {:ok, %{}}
  end

  # Create game if it does not exist. Join if it already exists
  @impl true
  def handle_call({:join_game, session_id}, _from, state) do
    new_player = %Player{
      id: session_id,
      money: 200,
      position: 0,
      # TODO: Randomly assign value
      sprite_id: 0,
      cards: [],
      in_jail: false,
      jail_turns: 0,
      turns_taken: 0
    }

    case :ets.lookup(@game_store, :game) do
      # If the game already exists
      [{:game, existing_game}] ->
        if length(existing_game.players) >= @max_player do
          {:reply, {:err, "Maximum 6 Players"}, state}
        else
          # Add player to the existing game
          updated_game = update_in(existing_game.players, &[new_player | &1])
          :ets.insert(@game_store, {:game, updated_game})
          {:reply, {:ok, updated_game}, updated_game}
        end

      # If the game doesn't exist
      [] ->
        new_game = %__MODULE__{
          players: [new_player],
          properties: [],
          deck: nil,
          current_player: nil,
          active_card: nil,
          turn: 0
        }

        :ets.insert(@game_store, {:game, new_game})
        {:reply, {:ok, new_game}, new_game}
    end
  end

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

  # Handle rolling dice for not in jail players
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

    updated_game =
      if current_tile.type in ["community", "chance"] do
        case Deck.draw_card(updated_game.deck, current_tile.type) do
          {:ok, card} ->
            case card.effect do
              {effect, _value} when effect in [:pay, :earn] ->
                player_after_effect =
                  GameObjects.Card.apply_effect(card, updated_game.current_player)

                updated_game = update_player(updated_game, player_after_effect)
                %{updated_game | active_card: card}

              {effect, _value} when effect == :get_out_of_jail ->
                owned_card = GameObjects.Card.mark_as_owned(card)
                updated_deck = Deck.update_deck(updated_game.deck, owned_card)
                new_player_state = Player.add_card(updated_game.current_player, owned_card)
                updated_game = update_player(updated_game, new_player_state)
                %{updated_game | deck: updated_deck, active_card: owned_card}

              _ ->
                %{updated_game | active_card: card}
            end

          {:error, _reason} ->
            updated_game
        end
      else
        updated_game
      end

    {{dice, sum, is_doubles}, current_tile, updated_game}
  end

  # Move player and handle passing go
  defp move_player(player, steps) do
    old_position = player.position
    new_position = rem(old_position + steps, 40)
    passed_go = old_position + steps >= 40 && !player.in_jail
    updated_player = %{player | position: new_position}

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

  # Remove player from the game.
  # Updates the state in ETS
  @impl true
  def handle_call({:leave_game, session_id}, _from, state) do
    updated_state =
      update_in(state.players, fn players ->
        Enum.reject(players, fn player -> player.id == session_id end)
      end)

    :ets.insert(@game_store, {:game, updated_state})
    {:reply, {:ok, updated_state}, updated_state}
  end

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
  def handle_call({:play_card, session_id, card_id}, _from, state) do
    current_player = state.current_player

    if current_player.id != session_id do
      {:reply, {:err, "Invalid session ID"}, state}
    else
      case Enum.find(Player.get_cards(current_player), fn card -> card.id == card_id end) do
        nil ->
          {:reply, {:err, "Card not found in player's hand"}, state}

        card ->
          player_after_effect = GameObjects.Card.apply_effect(card, current_player)
          player_after_effect = Player.remove_card(player_after_effect, card)

          updated_players =
            Enum.map(state.players, fn player ->
              if player.id == current_player.id, do: player_after_effect, else: player
            end)

          updated_game = %{
            state
            | players: updated_players,
              current_player: player_after_effect,
              active_card: nil
          }

          MonopolyWeb.Endpoint.broadcast("game_state", "card_played", updated_game)
          {:reply, {:ok, updated_game}, updated_game}
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
