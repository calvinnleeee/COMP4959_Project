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
  @initial_money 1500
  @board_size 40

  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :money,
    :sprite_id,
    :position,
    :properties,
    :cards,
    :in_jail,
    :jail_turns,
    :turns_taken,
    :rolled,
    :active
  ]

  # Type definition: when refering to it, use __MODULE__.t()
  @type t :: %__MODULE__{
          id: any(),
          name: String.t(),
          money: integer(),
          sprite_id: integer(),
          position: integer(),
          properties: [] | [%GameObjects.Property{}],
          cards: [] | [%GameObjects.Card{}],
          in_jail: boolean(),
          jail_turns: integer(),
          turns_taken: integer(),
          rolled: boolean(),
          active: boolean()
        }

  @doc """
  Creates a new player with the given id, name, and sprite_id.
  Default player money is set by the @initial_money constant, everything not passed in is set to 0 or it's type equivalent.
  """
  @spec new(any(), String.t(), integer()) :: __MODULE__.t()
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
      turns_taken: 0,
      rolled: false,
      active: true
    }
  end

  # docstring format gifted to us by ̷t̷r̷a̷u̷m̷a Chris.

  @doc """
  Gets a player's ID. Returns the session id.
  """
  @spec get_id(__MODULE__.t()) :: any()
  def get_id(player) do
    player.id
  end

  @doc """
  Gets a player's name. Returns a string representing the player's name.
  """
  @spec get_name(__MODULE__.t()) :: String.t()
  def get_name(player) do
    player.name
  end

  @doc """
  Gets a player's Money. Returns an integer represnting the player's money count.
  """
  @spec get_money(__MODULE__.t()) :: integer()
  def get_money(player) do
    player.money
  end

  @doc """
  Gets a player's sprite id. Returns a string representing the player's sprite id.
  """
  @spec get_sprite_id(__MODULE__.t()) :: String.t()
  def get_sprite_id(player) do
    player.sprite_id
  end

  @doc """
  Gets a player's Position. Returns an integer representing the index of the postion of the player on the board tiles from 0 to 39.
  """
  @spec get_position(__MODULE__.t()) :: integer()
  def get_position(player) do
    player.position
  end

  @doc """
  Gets a player's properties. Returns a list of properties the player owns.
  """
  @spec get_properties(__MODULE__.t()) :: [%GameObjects.Property{}]
  def get_properties(player) do
    player.properties
  end

  @doc """
  Gets a player's cards. Returns a list of cards the player owns.
  """
  @spec get_cards(__MODULE__.t()) :: [%GameObjects.Card{}]
  def get_cards(player) do
    player.cards
  end

  @doc """
  Gets a player's in jail state. Returns a boolean where false is not in jail and true is in jail.
  """
  @spec get_in_jail(__MODULE__.t()) :: boolean()
  def get_in_jail(player) do
    player.in_jail
  end

  @doc """
  Gets a player's jail_turns. Returns an integer representing the number of turns until a player is released from jail.
  """
  @spec get_jail_turns(__MODULE__.t()) :: integer()
  def get_jail_turns(player) do
    player.jail_turn
  end

  @doc """
  Creates a new Player with money set to 'num'. Returns a Player struct.
  """
  @spec set_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  def set_money(player, num) do
    %{player | money: num}
  end

  @doc """
  Sets the player's position to 'position'. Returns a Player struct.
  """
  @spec set_position(__MODULE__.t(), integer()) :: __MODULE__.t()
  def set_position(player, position) do
    %{player | position: position}
  end

  @doc """
  Sets the player's jail status to 'in_jail'. Returns a Player struct.
  """
  @spec set_in_jail(__MODULE__.t(), boolean()) :: __MODULE__.t()
  def set_in_jail(player, in_jail) do
    %{player | in_jail: in_jail}
  end

  @doc """
  Sets the player's rolled status to 'rolled'. Returns a Player struct.
  """
  @spec set_rolled(__MODULE__.t(), boolean()) :: __MODULE__.t()
  def set_rolled(player, rolled) do
    %{player | rolled: rolled}
  end

  @doc """
  Creates a new Player with jail_turn set to 'num'. Returns a Player struct.
  """
  @spec set_jail_turn(__MODULE__.t(), integer()) :: __MODULE__.t()
  def set_jail_turn(player, num) do
    %{player | jail_turns: num}
  end

  @doc """
  Adds a property to the player's properties list. Returns a Player struct.
  """
  @spec add_property(__MODULE__.t(), %GameObjects.Property{}) :: __MODULE__.t()
  def add_property(player, tile) do
    %{player | properties: Enum.concat(get_properties(player), [tile])}
  end

  @doc """
  Creates a new Player with new card added to card. Returns a Player struct.
  """
  @spec add_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t()
  def add_card(player, card) do
    %{player | cards: [card | get_cards(player)]}
  end

  @doc """
  Creates a new Player with money increased by 'amount'. Returns a Player struct.
  """
  @spec add_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  def add_money(player, amount) do
    %{player | money: get_money(player) + amount}
  end

  @doc """
  Creates a new Player with card removed. If card not present returns player with cards as is. Returns a Player struct.
  """
  @spec remove_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t()
  def remove_card(player, card) do
    %{player | cards: List.delete(get_cards(player), card)}
  end

  @doc """
  Creates a new Player with money reduced by 'amount'. Money can drop to negtaive amounts. Returns a Player struct.
  """
  @spec lose_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  def lose_money(player, amount) do
    %{player | money: get_money(player) - amount}
  end

  @doc """
  Transfers money between two players.
  The first player loses the amount, and the second player gains it.
  """
  @spec lose_money(__MODULE__.t(), __MODULE__.t(), integer()) :: {__MODULE__.t(), __MODULE__.t()}
  def lose_money(player1, player2, amount) do
    {
      %{player1 | money: get_money(player1) - amount},
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
