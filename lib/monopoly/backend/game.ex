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
  @max_player = 6

  # Game struct definition
  defstruct [:state, :players, :board, :current_player, :logs]

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
  def join_game(player_pid, player_web_socket) do
    GenServer.call(__MODULE__, {:join_game, player_pid, player_web_socket})
  end

  @doc """
  Remove the player from the game.
  """
  def leave_game(player_pid) do
    GenServer.call(__MODULE__, {:leave_game, player_pid})
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

  @doc """
    The game's main loop.

    Build this out iteratively.
  """
  defp game_loop(state) do
    # 1. Create Board and add to state
    # 2.
    receive do
      {:ok, game_start} ->
        # TODO: implement flow

        # Player's turn
        Enum.each(state.players, fn player ->
          Logger.info("#{inspect(player)}'s turn.")
          # Roll dice
          # Move player position
          # Check type of tile, properties, rent...etc.    [Massive Case statement]
          # React to tile
        end)

        # Check for win/Game over condition
        game_loop(state)

      _ ->
        "stub"
        # do more stuff
    end
  end

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
      state: [],
      players: players,
      board: Board.new(),
      current_player: List.first(players),
      logs: []
    }

    :ets.insert(@game_store, {:game, game})
    {:reply, :ok, game}
  end

  @doc """
    Create and Add new player to the Game.
  """
  @impl true
  def handle_call({:join_game, player_pid, player_web_socket}, _from, state) do
    new_player = %Player{
      pid: player_pid,
      web_socket: player_web_socket,
      money: 200,
      position: 0,
      in_jail: false
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
  def handle_call({:leave_game, player_pid}, _from, state) do
    updated_state =
      update_in(state.players, fn players ->
        Enum.reject(players, fn player -> player.pid == player_pid end)
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
    game_loop(state)
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
