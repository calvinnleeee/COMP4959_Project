defmodule GameObjects.Card do
  @moduledoc """
  This module represents a card and their attributes.
  """
  defstruct [:id, :name, :type, :effect, :owned]

  defimpl Jason.Encoder, for: GameObjects.Card do
    def encode(%GameObjects.Card{id: id, name: name, type: type, effect: effect, owned: owned}, opts) do
      map = %{
        id: id,
        name: name,
        type: type,
        effect: Tuple.to_list(effect),
        owned: owned
      }

      Jason.Encode.map(map, opts)
    end
  end

  def apply_effect(%__MODULE__{effect: {:pay, amount}}, player) do
    %{player | money: player.money - amount}
  end

  def apply_effect(%__MODULE__{effect: {:earn, amount}}, player) do
    %{player | money: player.money + amount}
  end

  def apply_effect(%__MODULE__{effect: {:get_out_of_jail, true}, owned: true} = card, player) do
    %{player | in_jail: false, cards: Enum.reject(player.cards, fn c -> c.id == card.id end)}
  end

  def apply_effect(%__MODULE__{effect: {:get_out_of_jail, true}}, player) do
    %{player | in_jail: false}
  end

  def apply_effect(_, player), do: player

  # Marks the card as 'owned'
  def mark_as_owned(card), do: %{card | owned: true}
end
