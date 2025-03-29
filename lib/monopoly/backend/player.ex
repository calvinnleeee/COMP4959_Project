defmodule GameObjects.Player do
  @moduledoc """
  This module represents a player and their attributes.

  properties field is a list of properites the player owns.

  id is the session id of the player.
  """

    defstruct [:id, :name, :money, :sprite_id, :position, :cards, :in_jail, :jail_turns]

    def get_id(player) do
        player.id
    end

    def get_money(player) do
        player.money
    end

    def get_position(player) do
        player.position
    end

    def get_in_jail(player) do
        player.in_jail
    end

    def set_money(player, num) do
        %{player | money: get_money(player) + num}
    end

    def set_jail_turn(player, num) do
        %{player | jail_turns: num}
    end

    def add_card(player, card) do
        %{player | cards: [card | get_cards(player)] }
    end

    def remove_card(player, card) do
        %{player | cards: List.delete(get_cards(player), card) }
    end

    def lose_money(player, amount) do
        %{player | money: get_money(player) - amount }
    end

end
