defmodule GameObjects.Card do
  @moduledoc """
  This module represents a card and their attributes.
  """

  defstruct [:id, :name, :type, :effect, :owned]

  def apply_effect(%__MODULE__{effect: {:pay, amount}}, player) do
    %{player | money: player.money - amount}
  end

  def apply_effect(%__MODULE__{effect: {:earn, amount}}, player) do
    %{player | money: player.money + amount}
  end

  def apply_effect(%__MODULE__{effect: {:get_out_of_jail, true}, owned: true} = card, player) do
    %{player |
    in_jail: false,
      card: Enum.reject(player.card, fn c -> c.id == card.id end)  # Remove from player's cards
    }
  end

  def apply_effect(%__MODULE__{effect: {:get_out_of_jail, true}}, player) do
    %{player | in_jail: false}
  end

  def apply_effect(_, player), do: player

  # Marks the card as 'owned'
  def mark_as_owned(card), do: %{card | owned: true}
end
