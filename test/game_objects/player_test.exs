# Generated player_text
defmodule GameObjects.PlayerTest do
  use ExUnit.Case
  alias GameObjects.Player

  # Global Variable
  # @initial_money 1500
  # @board_size 40

  # Hardcoded test
  @player_id "albert123"
  @player_name "Albert"
  @sprite_id 1

  # Basic setup test for hardcoded test : OK
  setup do
    player = Player.new(@player_id, @player_name, @sprite_id)
    %{player: player}
  end

  # new(id, name, sprite_id) creates player with default value : ok
  test "new/3 creates a player with default values", %{player: player} do
    assert player.id == @player_id
    assert player.name == @player_name
    assert player.money == 1500
    assert player.sprite_id == @sprite_id
    assert player.position == 0
    assert player.properties == []
    assert player.cards == []
    assert player.in_jail # Boolean
    assert player.jail_turns == 0
    assert player.turns_take == 0
    assert player.rolled # Boolean
  end

  # new(id, name, sprite_id) returns correct values : ERROR -> line 127 typo (player.jail_turn's')
  test "Getters for return correct values", %{player: player} do
    assert Player.get_id(player) == @player_id
    assert Player.get_name(player) == @player_name
    assert Player.get_money(player) == 1500
    assert Player.get_sprite_id(player) == @sprite_id
    assert Player.get_position(player) == 0
    assert Player.get_properties(player) == []
    assert Player.get_cards(player) == []
    refute Player.get_in_jail(player)
    assert Player.get_jail_turns(player) == 0
  end
end
