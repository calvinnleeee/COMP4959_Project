defmodule GameObjects.Player do
    @moduledoc """
    This module represents a player and their attributes.

    id: session id of the player.
    name: name of the player.
    money: amount of money the player has.
    sprite_id: id of the player's sprite.
    position: current position of the player on the board.
    properties: list of properties the player owns.
    cards: list of cards the player has.
    in_jail: boolean indicating if the player is in jail.
    jail_turns: number of turns until the player leaves jail.
    """
    @INITIAL_MONEY = 1500
    @BOARD_SIZE = 40

    defstruct [:id, :name, :money, :sprite_id, :position, :properties, :cards, :in_jail, :jail_turns]

    # Type definition: when refering to it, use __MODULE__.t()
    @type t :: %__MODULE__{
        id: any(),
        name: String.t(),
        money: integer(),
        sprite_id: String.t(),
        position: integer(),
        properties: List.t(),
        cards: List.t(),
        in_jail: boolean(),
        jail_turns: integer()
    }

    @doc """
    Creates a new player with the given id, name, and sprite_id.
    Default player money is set by the @INITIAL_MONEY constant, everything not passed in is set to 0 or it's type equivalent.
    """
    @spec new(any(), String.t(), String.t()) :: __MODULE__.t()
    def new(id, name, sprite_id) do
        %__MODULE__{
            id: id,
            name: name,
            money: @INITIAL_MONEY,
            sprite_id: sprite_id,
            position: 0,
            properties: [],
            cards: [],
            in_jail: false,
            jail_turns: 0,
        }
    end

    @spec get_name(__MODULE__.t()) :: String.t()
    def get_name(player) do
        player.name
    end

    @spec get_sprite_id(__MODULE__.t()) :: String.t()
    def get_sprite_id(player) do
        player.sprite_id
    end

    @spec get_cards(__MODULE__.t()) :: List.t()
    def get_cards(player) do
        player.cards
    end

    @spec get_jail_turns(__MODULE__.t()) :: integer()
    def get_jail_turns(player) do
        player.jail_turn
    end

    @spec set_position(__MODULE__.t(), integer()) :: __MODULE__.t()
    def set_position(player, position) do
        %{player | position: position}
    end

    @spec set_in_jail(__MODULE__.t(), boolean()) :: __MODULE__.t()
    def set_in_jail(player, in_jail) do
        %{player | in_jail: in_jail}
    end

    @spec add_property(__MODULE__.t(), %GameObjects.Property{}) :: __MODULE__.t()
    def add_property(player, tile) do
        %{player | properties: [get_properties(player) | tile]}
    end

    @spec lose_money(__MODULE__.t(), integer()) :: __MODULE__.t()
    def lose_money(player, amount) do
        %{player | amount: get_money(player) - amount}
    end

    @doc """
    Changes the player's position by the given amount.
    Uses Integer.mod/2 to wrap around the board, limit is set by the @BOARD_SIZE constant.
    """
    @spec move(__MODULE__.t(), integer()) :: __MODULE__.t()
    def move(player, step_count) do
        %{player | position: Integer.mod(get_position(player) + step_count, @BOARD_SIZE)}
    end
end
