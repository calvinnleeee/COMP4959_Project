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

  # Create player with default value : ok
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

end
