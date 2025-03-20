defmodule GameObjects.Game do
    @moduledoc """
    This module represents the Game object, which contains vital data and methods to run it.

    TODO: need to decide on the structure of the 'state'
    """

    defstruct [:state, :players, :board, :current_player, :logs]

    # Create a new game
    def new(players) do
      %Game{
        state: [],
        players: players,
        board: Board.new(),
        current_player: List.first(players),
        logs: []
      }
    end


end
