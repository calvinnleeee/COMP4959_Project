defmodule GameObjects.Game do
    @moduledoc """
    This module represents the Game object, which contains vital data and methods to run it.

    TODO: need to decide on the structure of the game's 'state', an ETS table?
    The struct instances themselves are states of sorts, but is that enough??

    `players` is a list a list of GameObjects.Player structs
    """

    defstruct [:state, :players, :board, :current_player, :logs]


    @doc """
    Create and initialize a new game.

    TODO: How should we actually store this instance once created???
    """
    def create_game(players) do
        %Game{
            state: [],
            players: players,
            board: Board.new(),
            current_player: List.first(players),
            logs: []
        }
    end


    @doc """
    Initialize a new Player instance and add it to the Game.
    Assumes the player's client will have a PID and Web socket
    """
    def join_game(player_pid, player_web_socket) do
        new_player = %GameObjects.Player{pid: player_pid, web_socket: player_web_socket, money: 200, position: 0, in_jail: false}
        update_in(game.players, &[new_player | &1])
    end


    @doc """
    Remove the player from the game.
    """
    def leave_game(player_pid) do
        update_in(game.players, fn players ->
            Enum.reject(players, fn player -> player.pid == player_pid end)
        end)
    end


    @doc """
    Start the main game loop.

    TODO: this will be iteratively built
    """
    def start_game(game) do
         receive do
            {:ok, game_start} ->
                # do stuff
                loop(game)
            _ -> "stub"
                # do more stuff
         end
    end


    # def end_turn() do

    # end


    @doc """
    Return the Game's current state.
    """
    def get_state(game) do
        game.state
    end

end
