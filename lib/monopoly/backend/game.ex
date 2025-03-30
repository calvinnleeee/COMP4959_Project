defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which contains vital data and methods to run it.

  `players` is a list of GameObjects.Player structs.
  """
  require Logger
  use GenServer
  alias ElixirLS.LanguageServer.Plugins.Phoenix
  alias GameObjects.{Deck, Player, Property}

  # CONSTANTS HERE
  # ETS table defined in application.ex
  @game_store Game.Store
  @max_player 6

  # Game struct definition
  # properties and players are both lists of their respective structs
  defstruct [:state, :players, :properties, :deck, :current_player, :active_card, :turn]

  # ---- Public API functions ----

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initialize a new Player instance and add it to the Game.
  # Assumes the player's client will have a PID and Web socket.
  def join_game(session_id, name, sprite_id) do
    GenServer.call(__MODULE__, {:join_game, session_id, name, sprite_id})
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

  def take_turn(session_id, tile) do
    GenServer.call(__MODULE__, {:take_turn, session_id, tile})
  end

  # ---- Private functions & GenServer Callbacks ----

  # ---- Private functions & GenServer Callbacks ---- #

  @impl true
  def init(_) do
    unless :ets.whereis(@game_store) != :undefined do
      :ets.new(@game_store, [:named_table, :public, :set])
    end

    {:ok, %{}}
  end

  # ---- PLayer related handles ---- #

  @doc """
    Add a new player to the game , update game state in ETS and broadcast change.
    If game doesn't exist in ETS, create a new game and add player to it.

    session_id:  unique identifier for a player (their socket).
    name: string, the player's chosen gamertag/nickname
    sprite_id: a unique number to identify the the sprite they've selected.
  """

  @impl true
  def handle_call({:join_game, session_id, name, sprite_id}, _from, state) do
    new_player = GameObjects.Player.new(session_id, name, sprite_id)

    case :ets.lookup(@game_store, :game) do
      # If the game already exists
      [{:game, existing_game}] ->
        if length(existing_game.players) >= @max_player do
          {:reply, {:err, "Maximum 6 Players"}, state}
        else
          # Add player to the existing game
          updated_game = update_in(existing_game.players, &[new_player | &1])
          :ets.insert(@game_store, {:game, updated_game})
          # Broadcast new game
          # TODO: Need other modules to subscribe
          Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:game_updated, updated_game})
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
        # broadcast state update
        Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:game_updated, new_game})
        {:reply, {:ok, new_game}, new_game}
    end
  end

  @doc """
    Remove the player from the game, update game state in ETS and broadcast change.
    session_id:  unique identifier for a player (their socket).
  """
  @impl true
  def handle_call({:leave_game, session_id}, _from, state) do
    updated_state =
      update_in(state.players, fn players ->
        Enum.reject(players, fn player -> player.id == session_id end)
      end)

    if Enum.empty?(updated_state.players) do
      :ets.delete(@game_store, :game)
      # Broadcast game deletion
      Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:game_deleted})
      {:reply, {:ok, "No players, Game deleted.", %{}}, %{}}
    else
      :ets.insert(@game_store, {:game, updated_state})
      Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:game_updated, updated_state})
      {:reply, {:ok, updated_state}, updated_state}
    end

    :ets.insert(@game_store, {:game, updated_state})
    {:reply, {:ok, updated_state}, updated_state}
  end

  @doc """
    End the current player's turn, but check if the rolled first, if not make them roll.
    Set next player as new current, reste the current player's turn count, and update state.
  """
  def handle_call({:end_turn, session_id}, _from, state) do
    case :ets.lookup(@game_store, {:game, state.current_player}) do
      [] ->
        {:reply, {:err, "No active game found."}, state}

      [{_key, current_player}] ->
        if GameObjects.Player.get_id(current_player) == session_id do
          if current_player.turns_taken > 0 do
            current_player_index = Enum.find_index(state.players, fn player ->
              player.id == state.current_player.id end)

            # Get next player
            next_player_index = rem(current_player_index + 1, length(state.players))
            next_player = Enum.at(state.players, next_player_index)

            # Reset turns_taken for the current player
            updated_players =
              List.replace_at(state.players, current_player_index, %{current_player | turns_taken: 0})

            # Update statu
            updated_state = %{
              state
              | players: updated_players,
                current_player: next_player,
                turn: state.turn + 1
            }

            :ets.insert(@game_store, {:game, updated_state})
            Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:turn_ended, updated_state})
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
            updated_players = Enum.map(state.players, fn player ->
              if player.id == current_player.id, do: updated_player, else: player
            end)
            # Clear the active card
            updated_state = %{state | players: updated_players, current_player: updated_player, active_card: nil}
            # Broadcast the state change
            Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:card_played, updated_state})
            {:reply, {:ok, updated_state}, updated_state}
      end
    end
  end

  @impl true
  def handle_call({:take_turn, session_id, tile}, _from, state) do #TBU
    # Take turn logic


    # When a player lands on the card tile
    if tile.type in ["community", "chance"] do #TBU
      case Deck.draw_card(state.deck, tile.type) do
        {:ok, card} ->
          updated_state = %{state | active_card: card}
          Phoenix.PubSub.broadcast(Monopoly.PubSub, "game_state", {:card_drawn, updated_state})
          {:reply, {:ok, updated_state}, updated_state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:ok, state}, state}
    end
  end



  # Terminate and save state on failure.
  @impl true
  def terminate(_reason, state) do
    :ets.insert(@game_store, {:game, state})
    :ok
  end
end
