defmodule GameObjects.PlayerTest do
  @moduledoc """
  This module is for testing lib/monopoly/backend/player.ex

  Tests are based on functionalities:
    - Creating players
    - Getter functions
    - Money management
    - Movement
    - Jail logic
    - Properties
    - Cards

  Two players are hard-coded for easy testings.
  """
  use ExUnit.Case
  alias GameObjects.Player

  @player_id "albert123"
  @player_name "Albert"
  @player_sprite_id 1

  @second_player_id "123Inez😉"
  @second_player_name "⑅*ॱ˖•.𝒾𝓃𝑒𝓏.•˖ॱ*⑅"
  @second_player_sprite_id 3285

  setup do
    player = Player.new(@player_id, @player_name, @player_sprite_id)
    second_player = Player.new(@second_player_id, @second_player_name, @second_player_sprite_id)
    %{player: player, second_player: second_player}
  end

  describe "Player.new/3" do
    test "creates a player with default values", %{player: player} do
      assert player.id == @player_id
      assert player.name == @player_name
      assert player.money == 1500
      assert player.sprite_id == @player_sprite_id
      assert player.position == 0
      assert player.properties == []
      assert player.cards == []
      refute player.in_jail
      assert player.jail_turns == 0
      assert player.turns_taken == 0
      refute player.rolled
      assert player.active
    end

    test "handles unicode names and custom IDs", %{second_player: player} do
      assert player.id == @second_player_id
      assert player.name == @second_player_name
      assert player.money == 1500
    end
  end

  describe "Getters" do
    test "return correct values", %{player: player} do
      assert Player.get_id(player) == @player_id
      assert Player.get_name(player) == @player_name
      assert Player.get_money(player) == 1500
      assert Player.get_sprite_id(player) == @player_sprite_id
      assert Player.get_position(player) == 0
      assert Player.get_properties(player) == []
      assert Player.get_cards(player) == []
      assert Player.get_in_jail(player) == false
    end
  end

  describe "Money management" do
    test "set_money/2 updates money but does not mutate original", %{player: player} do
      updated = Player.set_money(player, 100)
      assert updated.money == 100
      refute Player.get_money(player) == 100
    end

    test "add_money/2 adds correctly", %{player: player} do
      assert Player.add_money(player, 300).money == 1800
      assert Player.add_money(player, 0).money == 1500
    end

    test "add_money/2 supports negative values", %{player: player} do
      assert Player.add_money(player, -200).money == 1300
    end

    test "lose_money/2 subtracts money", %{player: player} do
      assert Player.lose_money(player, 500).money == 1000
    end

    test "lose_money/3 transfers money between players", %{player: p1, second_player: p2} do
      {p1_updated, p2_updated} = Player.lose_money(p1, p2, 250)
      assert p1_updated.money == 1250
      assert p2_updated.money == 1750
    end
  end

  describe "Movement" do
    test "set_position/2 sets a position", %{player: player} do
      assert Player.set_position(player, 5).position == 5
    end

    test "move/2 wraps board positions", %{player: player} do
      assert Player.move(player, 42).position == 2
      assert Player.move(player, -10).position == 30
    end
  end

  describe "Jail logic" do
    test "set_in_jail/2 toggles jail status", %{player: player} do
      jailed = Player.set_in_jail(player, true)
      assert jailed.in_jail
    end

    test "set_in_jail/2 called twice has no effect", %{player: player} do
      jailed = Player.set_in_jail(player, true)
      assert Player.set_in_jail(jailed, true) == jailed
    end

    test "set_jail_turn/2 sets the turn count", %{player: player} do
      assert Player.set_jail_turn(player, 3).jail_turns == 3
    end
  end

  describe "Properties" do
    test "add_property/2 adds property to player", %{player: player} do
      p = %GameObjects.Property{name: "Boardwalk"}
      assert Player.add_property(player, p).properties == [p]
    end

    test "add_property/2 allows duplicates", %{player: player} do
      p = %GameObjects.Property{name: "Boardwalk"}
      updated = player |> Player.add_property(p) |> Player.add_property(p)
      assert updated.properties == [p, p]
    end
  end

  describe "Cards" do
    test "add_card/2 adds card to player", %{player: player} do
      card = %GameObjects.Card{type: :get_out_of_jail}
      assert Player.add_card(player, card).cards == [card]
    end

    test "add_card/2 supports duplicates", %{player: player} do
      card = %GameObjects.Card{type: :advance_to_go}
      updated = player |> Player.add_card(card) |> Player.add_card(card)
      assert updated.cards == [card, card]
    end

    test "remove_card/2 removes one copy only", %{player: player} do
      card = %GameObjects.Card{type: :get_out_of_jail}
      player_with_dupes = player |> Player.add_card(card) |> Player.add_card(card)
      updated = Player.remove_card(player_with_dupes, card)
      assert updated.cards == [card]
    end

    test "remove_card/2 does nothing if card not owned", %{player: player} do
      card = %GameObjects.Card{type: :does_not_exist}
      assert Player.remove_card(player, card).cards == []
    end
  end
end
