defmodule GameObjects.Deck do
  alias GameObjects.Card

  # Initializes the full deck of cards with both Community Chest and Chance cards.
  def init_deck do
    init_community_chest() ++ init_chance_cards()
    |> Enum.shuffle()
  end

  # Initializes Community Chest cards with appropriate effects.
  def init_community_chest do
    [
      %Card{id: 0, name: "Doctor's fees", type: "community", effect: {:pay, 50}, owned: false},
      %Card{id: 1, name: "Bank error in your favor", type: "community", effect: {:earn, 200}, owned: false},
      %Card{id: 2, name: "Get Out of Jail Free", type: "community", effect: {:get_out_of_jail, true}, owned: false},
      %Card{id: 3, name: "Holiday fund matures", type: "community", effect: {:earn, 100}, owned: false},
      %Card{id: 4, name: "Hospital Fees", type: "community", effect: {:pay, 50}, owned: false},
    ]
  end

  # Initializes Chance cards with appropriate effects.
  def init_chance_cards do
    [
      %Card{id: 5, name: "Bank pays you dividend of $50", type: "chance", effect: {:earn, 50}, owned: false},
      %Card{id: 6, name: "Pay poor tax of $50", type: "chance", effect: {:pay, 50}, owned: false},
      %Card{id: 7, name: "You have been elected Chairman of the Board", type: "chance", effect: {:pay, 100}, owned: false},
      %Card{id: 8, name: "Your building loan matures", type: "chance", effect: {:earn, 150}, owned: false},
      %Card{id: 9, name: "Get Out of Jail Free", type: "chance", effect: {:get_out_of_jail, true}, owned: false}
    ]
  end

  def draw_card(deck, type) do
    shuffled_deck = Enum.shuffle(deck)

    case Enum.find(shuffled_deck, &(&1.owned == false and &1.type == type)) do
      nil -> {:error, "No available cards in the deck"}
      card -> {:ok, card}
    end
  end

  def update_deck(deck, updated_card) do
    Enum.map(deck, fn c -> if c.id == updated_card.id, do: updated_card, else: c end)
  end

end
