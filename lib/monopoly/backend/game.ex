defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which contains vital data and methods to run it.

  `players` is a list of GameObjects.Player structs.
  """
  require Logger
  use GenServer
  alias GameObjects.{Deck, Player}

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
      sprite_id: 0, # TODO: Randomly assign value
      cards: [],
      in_jail: false,
      jail_turns: 0
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
          active_acrd: nil,
          turn: 0
        }

        :ets.insert(@game_store, {:game, new_game})
        {:reply, {:ok, new_game}, new_game}
    end
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
      updated_state = put_in(updated_players.deck, Deck.init_deck())
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

  # Terminate and save state on failure.
  @impl true
  def terminate(_reason, state) do
    :ets.insert(@game_store, {:game, state})
    :ok
  end
end
