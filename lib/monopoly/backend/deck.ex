defmodule GameObjects.Deck do
  alias GameObjects.Card
  @cards_path Path.join(:code.priv_dir(:monopoly), "data/cards.json")

  def init_deck do
    @cards_path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(&parse_card/1)
    |> Enum.shuffle()
  end

  defp parse_card(%{
         "id" => id,
         "name" => name,
         "type" => type,
         "effect" => [effect_type, value],
         "owned" => owned
       }) do
    %Card{
      id: id,
      name: name,
      type: type,
      effect: {String.to_atom(effect_type), value},
      owned: owned
    }
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
