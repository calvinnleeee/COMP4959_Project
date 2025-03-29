defmodule GameObjects.DeckTest do
  use ExUnit.Case
  alias GameObjects.{Deck, Card}

  describe "init_deck/0" do
    test "returns a non-empty shuffled list of cards" do
      deck = Deck.init_deck()
      assert is_list(deck)
      assert length(deck) > 0
      assert Enum.all?(deck, fn card -> match?(%Card{}, card) end)
    end

    test "includes both community and chance card types" do
      deck = Deck.init_deck()
      types = Enum.map(deck, & &1.type) |> Enum.uniq()
      assert "community" in types
      assert "chance" in types
    end

    test "each card has required fields" do
      deck = Deck.init_deck()

      Enum.each(deck, fn %Card{} = card ->
        assert is_integer(card.id)
        assert is_binary(card.name)
        assert card.type in ["community", "chance"]
        assert is_tuple(card.effect)
        assert is_boolean(card.owned)
      end)
    end
  end

  describe "draw_card/2" do
    test "returns a card of the community type" do
      deck = Deck.init_deck()
      {:ok, card} = Deck.draw_card(deck, "community")
      assert card.type == "community"
    end

    test "returns a card of the chance type" do
      deck = Deck.init_deck()
      {:ok, card} = Deck.draw_card(deck, "chance")
      assert card.type == "chance"
    end

    test "returns different cards on successive draws" do
      deck = Deck.init_deck()
      {:ok, card1} = Deck.draw_card(deck, "chance")
      updated_deck = Deck.update_deck(deck, %{card1 | owned: true})
      {:ok, card2} = Deck.draw_card(updated_deck, "chance")

      assert card1.id != card2.id
    end

    test "returns error if no cards of that type are available" do
      deck = Deck.init_deck()
      owned_deck = Enum.map(deck, &Map.put(&1, :owned, true))
      assert {:error, _} = Deck.draw_card(owned_deck, "chance")
    end
  end

  describe "update_deck/2" do
    test "updates the card in the deck with the same id" do
      deck = Deck.init_deck()
      [first | _] = deck
      updated_card = %{first | owned: true}
      updated_deck = Deck.update_deck(deck, updated_card)

      assert Enum.any?(updated_deck, fn c -> c.id == first.id and c.owned == true end)
    end

    test "does not modify unrelated cards" do
      deck = Deck.init_deck()
      [first | rest] = deck
      updated_card = %{first | owned: true}
      updated_deck = Deck.update_deck(deck, updated_card)

      rest_ids = Enum.map(rest, & &1.id)
      updated_rest_ids = Enum.map(updated_deck -- [updated_card], & &1.id)
      assert rest_ids == updated_rest_ids
    end

    test "returns deck of same length after update" do
      deck = Deck.init_deck()
      updated_card = %{hd(deck) | owned: true}
      updated_deck = Deck.update_deck(deck, updated_card)

      assert length(deck) == length(updated_deck)
    end
  end
end
