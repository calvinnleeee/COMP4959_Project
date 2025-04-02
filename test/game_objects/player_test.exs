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
  @player_sprite_id 1

  # Basic setup test for hardcoded test : OK
  setup do
    player = Player.new(@player_id, @player_name, @player_sprite_id)
    %{player: player}
  end

  # new(id, name, player_sprite_id) creates player with default value : ok
  test "new/3 creates a player with default values", %{player: player} do
    assert player.id == @player_id
    assert player.name == @player_name
    assert player.money == 1500
    assert player.player_sprite_id == @player_sprite_id
    assert player.position == 0
    assert player.properties == []
    assert player.cards == []
    assert player.in_jail # Boolean
    assert player.jail_turns == 0
    assert player.turns_take == 0
    assert player.rolled # Boolean
  end

  # new(id, name, player_sprite_id) returns correct values : ERROR -> line 127 typo (player.jail_turn's')
  test "Getters for returning correct values", %{player: player} do
    assert Player.get_id(player) == @player_id
    assert Player.get_name(player) == @player_name
    assert Player.get_money(player) == 1500
    assert Player.get_sprite_id(player) == @player_sprite_id
    assert Player.get_position(player) == 0
    assert Player.get_properties(player) == []
    assert Player.get_cards(player) == []
    refute Player.get_in_jail(player)
    assert Player.get_jail_turns(player) == 0
  end

  # M O N E Y
  # set_money(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  test "set_money/2 updates player's money", %{player: player} do
    updated = Player.set_money(player, 100)
    assert updated.money == 100
  end

  # add_money(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  test "add_money/2 increases player's money", %{player: player} do
    updated = Player.add_money(player, 200)
    assert updated.money == 1700
  end

  # lose_money(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  test "lose_money/2 reduces player's money", %{player: player} do
    updated = Player.lose_money(player, 300)
    assert updated.money == 1200
  end

  # @spec lose_money(__MODULE__.t(), __MODULE__.t(), integer()) :: {__MODULE__.t(), __MODULE__.t()}
  test "lose_money/3 transfers money between players", %{player: player1} do
    player2 = Player.new("player2", "Inez", 2)
    {p1_after, p2_after} = Player.lose_money(player1, player2, 500)

    assert p1_after.money == 1000
    assert p2_after.money == 2000
  end

  # M O V E  L O G I C
  # set_position(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  test "set_position/2 sets the position", %{player: player} do
    updated = Player.set_position(player, 10)
    assert updated.position == 10
  end

  # move(__MODULE__.t(), integer()) :: __MODULE__.t()
  # Integer.mod/2 to wrap around the board, limit is set by the @board_size (40) constant
  test "move/2 wraps around board size", %{player: player} do
    # When the number is over 40
    moved = Player.move(player, 42)
    assert moved.position == 2
  end





end
