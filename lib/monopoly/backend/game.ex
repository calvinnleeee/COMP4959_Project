defmodule GameObjects.Game do
  @moduledoc """
  This module represents the Game object, which contains vital data and methods to run it.

  `players` is a list of GameObjects.Player structs.
  """
  require Logger
  use GenServer
  alias GameObjects.{Player, Board}

  # CONSTANTS HERE
  # ETS table defined in application.ex
  @game_store Game.Store
  @max_player 6

  # Game struct definition
  # properties and players are both lists of their respective structs
  defstruct [:state, :players, :properties, :current_player, :turn]

  # ---- Public API functions ----

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Create and initialize a new game.
  """
  def create_game(players) do
    GenServer.call(__MODULE__, {:create_game, players})
  end

  @doc """
  Initialize a new Player instance and add it to the Game.
  Assumes the player's client will have a PID and Web socket.
  """
  def join_game(session_id) do
    GenServer.call(__MODULE__, {:join_game, session_id})
  end

  @doc """
  Remove the player from the game.
  """
  def leave_game(session_id) do
    GenServer.call(__MODULE__, {:leave_game, session_id})
  end

  @doc """
  Start the main game loop.
  """
  def start_game() do
    GenServer.cast(__MODULE__, :start_game)
  end

  @doc """
  Return the Game's current state.
  """
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

  @doc """
    Create a Game struct and store it in the ETS
  """
  @impl true
  def handle_call({:create_game, players}, _from, _state) do
    game = %__MODULE__{
      players: players,
      properties: [],
      current_player: List.first(players),
      turn: 0,
    }

    :ets.insert(@game_store, {:game, game})
    {:reply, :ok, game}
  end

  @doc """
    Create and Add new player to the Game.
  """
  @impl true
  def handle_call({:join_game, session_id}, _from, state) do
    new_player = %Player{
      id: session_id,
      money: 200,
      position: 0,
      sprite_id: 0, #TODO: randomly asign value
      in_jail: false,
      jail_turns: 0
    }

    # add player struct to list of players in state
    updated_state = update_in(state.players, &[new_player | &1])
    :ets.insert(@game_store, {:game, updated_state})
    {:reply, :ok, updated_state}
  end

  @doc """
    Remove player from the game.
    Updates the state in ETS
  """
  @impl true
  def handle_call({:leave_game, session_id}, _from, state) do
    updated_state =
      update_in(state.players, fn players ->
        Enum.reject(players, fn player -> player.id == session_id end)
      end)

    :ets.insert(@game_store, {:game, updated_state})
    {:reply, :ok, updated_state}
  end

  @doc """
    Get current game state.
  """
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
    Start the game loop.
  """
  @impl true
  def handle_cast(:start_game, state) do
    {:noreply, state}
  end

  @doc """
    Terminate and save state on failure.
  """
  @impl true
  def terminate(_reason, state) do
    :ets.insert(@game_store, {:game, state})
    :ok
  end
end
