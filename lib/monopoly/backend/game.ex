defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which holds vital state information and defines
  the methods for handling game logic.
  """
  require Logger
  use GenServer
  alias GameObjects.Game
  alias GameObjects.{Deck, Player, Property, Dice}

  ##############################################################
  # Constants

  @game_store Game.Store
  @max_player 6
  @jail_position 10
  @go_to_jail_position 30
  @income_tax_position 4
  @parking_tax_position 20
  @luxury_tax_position 38
  @go_bonus 200
  @jail_fee 50
  @luxury_tax_fee 75
  # we will keep income tax as a static 200 because it is easy.
  @income_tax_fee 200
  # we will keep parking tax as a static 100 because it is easy.
  @parking_tax_fee 200

  ##############################################################
  # Game struct definition

  # - properties and players are both lists of their respective structs
  # - deck is a list of Card structs
  # - current_player is the current player's struct, containing their state
  # - active_card tracks the current card being played by the current player
  # - turn is the current turn number
  defstruct [:players, :properties, :deck, :current_player, :active_card, :winner, :turn]

  ##############################################################
  # Public API functions

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initialize a new Player instance and add it to the Game.
  # Assumes the player's client will have a PID and web socket.
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

  # Delete the active game instance from the ETS table.
  def delete_game() do
    GenServer.call(__MODULE__, :delete_game)
  end

  # Return the Game's current state.
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # End the current player's turn.
  def end_turn(session_id) do
    GenServer.call(__MODULE__, {:end_turn, session_id})
  end

  # Roll the dice for the current player.
  def roll_dice(session_id) do
    GenServer.call(__MODULE__, {:roll_dice, session_id})
  end

  # Upgrade a property
  def upgrade_property(session_id, property_id) do
    GenServer.call(__MODULE__, {:upgrade_property, session_id, property_id})
  end

  # Downgrade a property
  def downgrade_property(session_id, property_id) do
    GenServer.call(__MODULE__, {:upgrade_property, session_id, property_id})
  end

  # Allow the current player to buy a property.
  def buy_property(session_id, tile) do
    GenServer.call(__MODULE__, {:buy_property, session_id, tile})
  end

  # Set a player inactive when they disconnect
  def set_player_inactive(session_id) do
    GenServer.call(__MODULE__, {:set_player_inactive, session_id})
  end

  # Set a player active if they reconnect
  def set_player_active(session_id) do
    GenServer.call(__MODULE__, {:set_player_active, session_id})
  end

  # Initialization implementation for the GenServer.
  @impl true
  def init(_) do
    unless :ets.whereis(@game_store) != :undefined do
      :ets.new(@game_store, [:named_table, :public, :set])
    end

    {:ok, %{}}
  end

  ##############################################################
  # Player-related handlers

  @doc """
    Add a new player to the game, update the game state in the ETS table, and
    broadcast the change. A new game is made if one doesn't exist in the table.
    The player added is tracked using their `session_id`.

    session_id: unique identifier for a player (their socket)
    name: a string representing the player's chosen/given nickname
    sprite_id: a unique number identifying the sprite they've selected

    Replies with {:ok, updated_game_state} if successful, else {:err, reason}.
  """
  @impl true
  def handle_call({:join_game, session_id}, _from, _state) do
    case :ets.lookup(@game_store, :game) do
      # If the game already exists
      [{:game, existing_game}] ->
        if Enum.any?(existing_game.players, fn player -> player.id == session_id end) do
          # Provide the game state to the player if they are already in the game
          MonopolyWeb.Endpoint.broadcast("game_state", "game_update", existing_game)
          {:reply, {:ok, existing_game}, existing_game}
        else
          # Let the player join the game if the game is not full
          if length(existing_game.players) >= @max_player do
            {:reply, {:err, "Maximum 6 Players"}, existing_game}
          else
            if existing_game.current_player == nil do
              player_count = length(existing_game.players)
              # change later for custom names
              name = "Player #{player_count + 1}"
              # currently assigns a sprite to them, may allow choice later
              sprite_id = player_count
              new_player = GameObjects.Player.new(session_id, name, sprite_id)

              updated_game = update_in(existing_game.players, &[new_player | &1])
              :ets.insert(@game_store, {:game, updated_game})
              MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_game)
              {:reply, {:ok, updated_game}, updated_game}
            else
              {:reply, {:err, "Game has already started"}, existing_game}
            end
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
          winner: nil,
          turn: 0
        }

        :ets.insert(@game_store, {:game, new_game})
        MonopolyWeb.Endpoint.broadcast("game_state", "game_update", new_game)
        {:reply, {:ok, new_game}, new_game}
    end
  end

  @doc """
    Rolls the dice for the current player, defers the handling logic to another
    function depending on the player's current position (whether in jail or not).
    Updates the position of the current player after the roll.

    session_id: the session ID of the player rolling the dice

    Replies with :ok and a collection of data if successful, else :err with a reason.
  """
  @impl true
  def handle_call({:roll_dice, session_id}, _from, state) do
    # Check for an active game, otherwise ignore the call
    case :ets.lookup(@game_store, :game) do
      [{:game, game}] ->
        current_player = game.current_player

        # Only allow the current player to roll the dice
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

          # For Checking whether the current_player should be game over
          updated_player = player_lost_condition(updated_game.current_player)

          current_player_index =
            Enum.find_index(updated_game.players, fn player ->
              player.id == updated_game.current_player.id
            end)

          updated_players =
            List.replace_at(updated_game.players, current_player_index, updated_player)

          winner = game_over_condition(updated_players)

          updated_game = %{
            updated_game
            | players: updated_players,
              current_player: updated_player,
              winner: winner
          }

          # Storing the game state
          :ets.insert(@game_store, {:game, updated_game})

          # Broadcast the game state
          MonopolyWeb.Endpoint.broadcast("game_state", "game_update", updated_game)
          {:reply, {:ok, dice_result, current_position, current_tile, updated_game}, updated_game}
        end

      [] ->
        {:reply, {:err, "No active game"}, state}
    end
  end

  # Handle the result of rolling the dice while a player is in jail.
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
          # !! requires a check for money <= 0, player loses if they can't pay
          player = Player.lose_money(player, @jail_fee)
          move_player(player, sum)

        :stay_in_jail ->
          %{player | jail_turns: player.jail_turns + 1}
      end

    current_tile = get_tile(game, updated_player.position)
    updated_game = update_player(game, updated_player)
    {{dice, sum, jail_status}, current_tile, updated_game}
  end

  # Handle the result of rolling the dice if a player is not in jail.
  defp handle_normal_roll(game) do
    current_player = game.current_player

    # Update player after dice roll
    {dice, sum, is_doubles} = Dice.roll()

    current_player = %{
      current_player
      | turns_taken: if(is_doubles, do: current_player.turns_taken + 1, else: 0),
        rolled: !is_doubles
    }

    should_go_to_jail = Dice.check_for_jail(current_player.turns_taken, is_doubles)

    current_player =
      if should_go_to_jail do
        %{current_player | in_jail: true, position: @jail_position, turns_taken: 0}
      else
        move_player(current_player, sum)
      end

    current_tile = get_tile(game, current_player.position)
    updated_game = update_player(game, current_player)
    current_state = updated_game

    # Checking what the user has landed on.
    updated_game =
      cond do
        # if player lands on card
        current_tile.type in ["community", "chance"] ->
          case Deck.draw_card(updated_game.deck, current_tile.type) do
            {:ok, card} ->
              case card.effect do
                {:get_out_of_jail, _value} ->
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

        # if player lands on a property
        current_tile.type not in ["community", "chance", "tax", "go", "jail", "go_to_jail"] ->
          if GameObjects.Property.is_owned(current_tile) do
            # check who owns it
            owner = GameObjects.Property.get_owner(current_tile)

            case owner.id == current_player.id do
              false ->
                prop_rent = GameObjects.Property.charge_rent(current_tile, sum)
                # pay rent
                if GameObjects.Player.get_money(current_player) >= prop_rent do
                  {player_minus_rent, owner_plus_rent} =
                    GameObjects.Player.lose_money(current_player, owner, prop_rent)

                  # update player and owner
                  updated_players =
                    Enum.map(current_state.players, fn p ->
                      cond do
                        p.id == current_player.id -> player_minus_rent
                        p.id == owner.id -> owner_plus_rent
                        true -> p
                      end
                    end)

                  updated_state = %{current_state | players: updated_players}
                  :ets.insert(@game_store, {:game, updated_state})
                  updated_state
                end

              true ->
                MonopolyWeb.Endpoint.broadcast("game_state", "upgradable_property", updated_game)
                updated_game
            end
          else
            # Property is Not owned, announce that via broadcast
            # Frontend will invoke the purchase flow
            MonopolyWeb.Endpoint.broadcast("game_state", "unowned_property", updated_game)
          end

        true ->
          updated_game
      end

    {{dice, sum, is_doubles}, current_tile, updated_game}
  end

  # Update the player's position based on the dice result, handles passing go.
  defp move_player(player, steps) do
    old_position = player.position
    updated_player = Player.move(player, steps)
    passed_go = old_position + steps >= 40 && !player.in_jail

    updated_player =
      cond do
        updated_player.position == @income_tax_position ->
          Player.lose_money(updated_player, @income_tax_fee)

        updated_player.position == @luxury_tax_position ->
          Player.lose_money(updated_player, @luxury_tax_fee)

        updated_player.position == @go_to_jail_position ->
          updated_player
          |> Player.set_in_jail(true)
          |> Player.set_position(@jail_position)

        updated_player.position == @parking_tax_position ->
          Player.lose_money(updated_player, @parking_tax_fee)

        passed_go ->
          Player.add_money(updated_player, @go_bonus)

        true ->
          updated_player
      end

    updated_player
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

  @doc """
    Removes a player from the game and updates the ETS table.

    session_id: the session ID of the player leaving the game

    Replies with :ok and the updated game state if successful, else :ok with an empty game.
  """
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
    End the current player's turn if they have rolled the dice already. The current
    player's turn count will reset and the next player will be set as the new current
    player.

    session_id: the session ID of the player ending their turn

    Replies with :ok
  """
  @impl true
  def handle_call({:end_turn, session_id}, _from, state) do
    case :ets.lookup(@game_store, :game) do
      [] ->
        {:reply, {:err, "No active game found."}, state}

      [{_key, game}] ->
        current_player = game.current_player

        if GameObjects.Player.get_id(current_player) == session_id do
          if current_player.rolled do
            # For Checking whether the current_player should be game over
            updated_player = player_lost_condition(current_player)

            current_player_index =
              Enum.find_index(state.players, fn player ->
                player.id == state.current_player.id
              end)

            updated_players = List.replace_at(state.players, current_player_index, updated_player)
            winner = game_over_condition(updated_players)
            state = %{state | players: updated_players, winner: winner}

            # Get next player
            next_player = find_next_active_player(state.players, current_player_index)

            # If the next player is in jail, check for and apply the get_out_of_jail card
            {next_player, state} =
              if next_player.in_jail do
                check_and_apply_get_out_of_jail_card(next_player, state)
              else
                {next_player, state}
              end

            # Reset turns_taken for the current player
            updated_players =
              List.replace_at(state.players, current_player_index, %{
                current_player
                | rolled: false
              })

            # Update state
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

  # Handler for applying a 'Get out of jail' card for the upcoming player if they have one,
  # before they begin their turn.
  defp check_and_apply_get_out_of_jail_card(next_player, state) do
    get_out_cards =
      Enum.filter(Player.get_cards(next_player), fn card ->
        case card.effect do
          {:get_out_of_jail, true} -> true
          _ -> false
        end
      end)

    if get_out_cards != [] do
      get_out_card = hd(get_out_cards)
      updated_next_player = GameObjects.Card.apply_effect(get_out_card, next_player)
      updated_next_player = Player.remove_card(updated_next_player, get_out_card)

      updated_players =
        Enum.map(state.players, fn player ->
          if player.id == next_player.id, do: updated_next_player, else: player
        end)

      updated_state = %{state | players: updated_players, active_card: nil}
      MonopolyWeb.Endpoint.broadcast("game_state", "card_played", updated_state)

      {updated_next_player, updated_state}
    else
      {next_player, state}
    end
  end

  # Check whether the current player should be marked as inactive (Game over)
  defp player_lost_condition(target_player) do
    if target_player != nil and target_player.money < 0 do
      %{target_player | active: false}
    else
      target_player
    end
  end

  # Check if there's a winner
  defp game_over_condition(players) do
    active_players = Enum.filter(players, fn player -> player.active end)

    if length(active_players) == 1 do
      hd(active_players)
    else
      nil
    end
  end

  # Skip inactive player
  defp find_next_active_player(players, current_index) do
    total = length(players)

    Enum.find_value(1..total, fn i ->
      index = rem(current_index + i, total)
      player = Enum.at(players, index)

      if player.active, do: player, else: nil
    end)
  end

  ##############################################################
  # Game-related handlers

  @doc """
    Gets the current state of the game.

    Replies with :ok and the current game.
  """
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @doc """
    Starts the game if there are enough players. Initializes the struct's missing
    values.

    Replies with :ok and the updated game state if successful, else :err with the reason.
  """
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

  @doc """
    Deletes the game from the ETS table if it exists.

    Replies with :ok and an empty game if successful, else :err with a reason.
  """
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

  # Update game state with property upgrade and reduced player money
  @impl true
  defp handle_call(:upgrade_property, session_id, property, state) do
    case :ets.lookup(@game_store, :game) do
      [{:game, game}] ->
        current_player = game.current_player

        if current_player.id != session_id do
          {:reply, {:err, "Not your turn"}, state}
        else
          property = get_property(game, property)
          #check with abdu if we assign owners with id
          if property.owner == current_player.id do

            {updated_property, cost} = property.build_upgrade(property)

            #money and player update
            #cost = property.house_price
            if cost == 0 do
              {:reply, {:err, "Cannot upgrade"}, state}
            end
            if current_player.money < cost do
              {:reply, {:err, "Not enough money"}, state}
            end
            updated_player = Player.lose_money(current_player, cost)
            player_updated_game = update_player(game, updated_player)

            #updated_property = Property.inc_upgrade(property)
            prop_updated_game = update_property(player_updated_game, updated_property)


            #store the updated game state in ETS
            :ets.insert(@game_store, {:game, prop_updated_game})
            {:reply, {:ok, prop_updated_game}, prop_updated_game}
          else
            {:reply, {:err, "You don't own this property"}, state}
          end
        end

      [] ->
        {:reply, {:err, "No active game"}, state}

    end
  end

  # Update game state with property downgrade and increased player money
  @impl true
  defp handle_call(:downgrade_property, session_id, property, state) do
    case :ets.lookup(@game_store, :game) do
      [{:game, game}] ->
        current_player = game.current_player

        if current_player.id != session_id do
          {:reply, {:err, "Not your turn"}, state}
        else
          property = get_property(game, property)
          #check with abdu if we assign owners with id
          if property.owner == current_player.id do

            {updated_property, cost} = property.sell_upgrade(property)

            Enum.forEach(game.properties, fn prop ->
              if prop.type == updated_property.type do
                if (abs(prop.upgrades - updated_property.upgrades)) > 0 do
                  {:reply, {:err, "Properties must be within one upgrade of each other"}, state}
                end
              end
            end)

            if (property.upgrade_level <= 1) do
                #sell property
                updated_property = Property.set_owner(updated_property, nil)
                # nil_owner_updated_game = update_property(game, updated_property)
                #set other props of same type to upgrade level 0
                updated_properties =
                  Enum.map(game.properties, fn property ->
                    if property.type == updated_property.type do
                      Property.set_upgrade(property, 0)
                    else
                      property
                    end
                  end)
                prop_updated_game = %{game | properties: updated_properties}
                updated_player = Player.add_money(current_player, property.buy_cost)
                player_updated_game = update_player(prop_updated_game, updated_player)
                #store the updated game state in ETS
                :ets.insert(@game_store, {:game, player_updated_game})
                {:reply, {:ok, player_updated_game}, player_updated_game}

            else
              # downgrade property
              if cost == 0 do
                {:reply, {:err, "Cannot downgrade"}, state}
              end
              updated_player = Player.add_money(current_player, cost)
              player_updated_game = update_player(game, updated_player)
              #updated_property = Property.inc_upgrade(property)
              prop_updated_game = update_property(player_updated_game, updated_property)
              #store the updated game state in ETS
              :ets.insert(@game_store, {:game, prop_updated_game})
              {:reply, {:ok, prop_updated_game}, prop_updated_game}
              #money and player update
              #cost = property.house_price
            end
          else
            {:reply, {:err, "You don't own this property"}, state}
          end
        end

      [] ->
        {:reply, {:err, "No active game"}, state}
    end
  end

  # Get property from game list by property id
  defp get_property(game, property) do
    Enum.find(game.properties, fn prop -> prop.id == property.id end)
  end

   # Update a player in the game state
  defp update_property(game, updated_property) do
    updated_properties =
      Enum.map(game.properties, fn property ->
        if property.id == updated_property.id do
          updated_property
        else
          property
        end
      end)

    %{game | properties: updated_properties}
  end

  @doc """
    Handles the buying logic of a property for the current player. The owner's property
    is updated, the player's money is deducted, and the game state is updated.

    session_id: the session ID of the player buying the property
    tile: the property being bought

    Replies with :ok and the updated game state if successful, else :err with a reason.
  """
  @impl true
  def handle_call({:buy_property, session_id, tile}, _from, state) do
    player = state.current_player

    cond do
      # Check that the tile is a property
      tile.type not in ["community", "chance", "tax", "go", "jail", "go_to_jail"] ->
        if GameObjects.Property.is_owned(tile) do
          {:reply, {:err, "Property already owned"}, state}
        else
          # updated_player_properties = GameObjects.Property.buy_property(tile, player)
          updated_property = GameObjects.Property.set_owner(tile, player.id)
          # Charge the player if has money
          if player.money >= GameObjects.Property.get_buy_cost(tile) do
            updated_player =
              GameObjects.Player.lose_money(player, GameObjects.Property.get_buy_cost(tile))

            updated_properties =
              Enum.map(state.properties, fn property ->
                if property.id == tile.id, do: updated_property, else: property
              end)

            updated_players =
              Enum.map(state.players, fn p ->
                if p.id == player.id, do: updated_player, else: p
              end)

            updated_state = %{state | properties: updated_properties, players: updated_players}
            :ets.insert(@game_store, {:game, updated_state})
            MonopolyWeb.Endpoint.broadcast("game_state", "property_bought", updated_state)
            {:reply, {:ok, updated_state}, updated_state}
          end
        end

      true ->
        {:reply, {:err, "Invalid tile"}, state}
    end
  end

  @doc """
    Sets a player as inactive in the game state. Should only be used when a player disconnects.
    session_id: the session ID of the player to be marked as inactive.
    Updates the player's `active` status to `false` and broadcasts the new game state.
    Replies with `{:ok, updated_state}` if successful.
  """
  @impl true
  def handle_call({:set_player_inactive, session_id}, _from, state) do
    updated_players =
      Enum.map(state.players, fn player ->
        if player.id == session_id and player.active do
          %{player | active: false}
        else
          player
        end
      end)

    updated_current_player =
      if state.current_player.id == session_id and state.current_player.active do
        %{state.current_player | active: false}
      else
        state.current_player
      end

    # Frontend should check whether the current player is inactive or not.
    # If so, FE should call end turn for the inactive player.
    updated_state = %{state | players: updated_players, current_player: updated_current_player}

    :ets.insert(@game_store, {:game, updated_state})
    MonopolyWeb.Endpoint.broadcast("game_state", "player_inactive", updated_state)

    {:reply, {:ok, updated_state}, updated_state}
  end

  @doc """
    Sets a player as active in the game state. Should only be used when a previously inactive
    player reconnects.
    session_id: the session ID of the player to be marked as active.
    Updates the player's `active` status to `true` if and only if they have money >=0 and broadcasts the new game state.
    Replies with `{:ok, updated_state}` if successful.
  """
  @impl true
  def handle_call({:set_player_active, session_id}, _from, state) do
    updated_players =
      Enum.map(state.players, fn player ->
        if player.id == session_id and not player.active and player.money >= 0 do
          %{player | active: true}
        else
          player
        end
      end)

    updated_state = %{state | players: updated_players}
    :ets.insert(@game_store, {:game, updated_state})
    MonopolyWeb.Endpoint.broadcast("game_state", "player_active", updated_state)

    {:reply, {:ok, updated_state}, updated_state}
  end

  @doc """
    Saves the current game state in the event the server crashes or terminates.
  """
  @impl true
  def terminate(_reason, state) do
    :ets.insert(@game_store, {:game, state})
    :ok
  end
end
