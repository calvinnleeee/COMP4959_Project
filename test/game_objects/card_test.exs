defmodule GameObjects.CardTest do
  use ExUnit.Case
  alias GameObjects.Card

  defmodule Player do
    defstruct [:id, :name, :money, :sprite_id, :position, :cards, :in_jail, :jail_turns]
  end

  setup do
    player = %Player{
      id: 1,
      name: "Test",
      money: 1000,
      sprite_id: "sprite-1",
      position: 0,
      cards: [],
      in_jail: true,
      jail_turns: 0
    }

    {:ok, player: player}
  end

  describe "apply_effect/2" do
    test "subtracts money when effect is :pay", %{player: player} do
      card = %Card{effect: {:pay, 200}}
      updated = Card.apply_effect(card, player)
      assert updated.money == 800
    end

    test "adds money when effect is :earn", %{player: player} do
      card = %Card{effect: {:earn, 150}}
      updated = Card.apply_effect(card, player)
      assert updated.money == 1150
    end

    test "sets in_jail to false with :get_out_of_jail effect", %{player: player} do
      card = %Card{effect: {:get_out_of_jail, true}}
      updated = Card.apply_effect(card, player)
      assert updated.in_jail == false
    end

    test "removes owned get-out-of-jail card from player's cards", %{player: player} do
      card = %Card{id: 99, effect: {:get_out_of_jail, true}, owned: true}
      player_with_card = %{player | cards: [card]}
      updated = Card.apply_effect(card, player_with_card)

      assert updated.in_jail == false
      assert updated.cards == []
    end

    test "returns unchanged player for unsupported effect", %{player: player} do
      card = %Card{effect: {:teleport, 3}} # unsupported effect
      updated = Card.apply_effect(card, player)
      assert updated == player
    end
  end

  describe "mark_as_owned/1" do
    test "sets card.owned to true" do
      card = %Card{id: 123, owned: false}
      updated = Card.mark_as_owned(card)
      assert updated.owned == true
    end
  end
end
