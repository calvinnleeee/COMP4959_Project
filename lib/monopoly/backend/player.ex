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
    @initial_money = 1500
    @board_size = 40

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
    Default player money is set by the @initial_money constant, everything not passed in is set to 0 or it's type equivalent.
    """
    @spec new(any(), String.t(), String.t()) :: __MODULE__.t()
    def new(id, name, sprite_id) do
        %__MODULE__{
            id: id,
            name: name,
            money: @initial_money,
            sprite_id: sprite_id,
            position: 0,
            properties: [],
            cards: [],
            in_jail: false,
            jail_turns: 0,
        }
    end

    def get_id(player) do
        player.id
    end

    @spec get_name(__MODULE__.t()) :: String.t()
    def get_name(player) do
        player.name
    end

    def get_money(player) do
        player.money
    end

    @spec get_sprite_id(__MODULE__.t()) :: String.t()
    def get_sprite_id(player) do
        player.sprite_id
    end

    def get_position(player) do
        player.position
    end

    @spec get_cards(__MODULE__.t()) :: List.t()
    def get_cards(player) do
        player.cards
    end

    def get_in_jail(player) do
        player.in_jail
    end

    @spec get_jail_turns(__MODULE__.t()) :: integer()
    def get_jail_turns(player) do
        player.jail_turn
    end

    def set_money(player, num) do
        %{player | money: get_money(player) + num}
    end

    @spec set_position(__MODULE__.t(), integer()) :: __MODULE__.t()
    def set_position(player, position) do
        %{player | position: position}
    end

    @spec set_in_jail(__MODULE__.t(), boolean()) :: __MODULE__.t()
    def set_in_jail(player, in_jail) do
        %{player | in_jail: in_jail}
    end

    def set_jail_turn(player, num) do
        %{player | jail_turns: num}
    end

    @spec add_property(__MODULE__.t(), %GameObjects.Property{}) :: __MODULE__.t()
    def add_property(player, tile) do
        %{player | properties: [get_properties(player) | tile]}
    end

    def add_card(player, card) do
        %{player | cards: [card | get_cards(player)] }
    end

    def remove_card(player, card) do
        %{player | cards: List.delete(get_cards(player), card) }
    end

    @spec lose_money(__MODULE__.t(), integer()) :: __MODULE__.t()
    def lose_money(player, amount) do
        %{player | amount: get_money(player) - amount}
    end

    @doc """
    Transfers money between two players.
    The first player loses the amount, and the second player gains it.
    """
    @spec lose_money(__MODULE__.t(), __MODULE__.t(), integer()) :: {__MODULE__.t(), __MODULE__.t()}
    def lose_money(player1, player2, amount) do
        {
            %{player | money: get_money(player) - amount},
            %{player2 | money: get_money(player2) + amount}
        }
    end

    @doc """
    Changes the player's position by the given amount.
    Uses Integer.mod/2 to wrap around the board, limit is set by the @board_size constant.
    """
    @spec move(__MODULE__.t(), integer()) :: __MODULE__.t()
    def move(player, step_count) do
        %{player | position: Integer.mod(get_position(player) + step_count, @board_size)}
    end

end
