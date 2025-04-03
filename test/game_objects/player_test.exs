# Generated player_text
defmodule GameObjects.PlayerTest do
  use ExUnit.Case
  alias GameObjects.Player

  # Test player 1: OK
  @player_id "albert123"
  @player_name "Albert"
  @player_sprite_id 1

  # Test player 2 with funcky string: OK
  @second_player_id "123Inez😉"
  @second_player_name "⑅*ॱ˖•. ·͙*̩̩͙˚̩̥̩ì̖̗n̖̹̍è̖̤z̖͎̥̩̥̏̀̀*̩̩͙‧͙ .•˖ॱ*⑅"
  @second_player_sprite_id 29832

  # Basic setup test for hardcoded test : OK
  setup do
    player = Player.new(@player_id, @player_name, @player_sprite_id)
    second_player = Player.new(@second_player_id, @second_player_name, @second_player_sprite_id)
    %{player: player, second_player: second_player}
  end

  # new(id, name, player_sprite_id) creates player with default value : ok
  test "new/3 creates a player with default values", %{player: player} do
    assert player.id == @player_id
    assert player.name == @player_name
    assert player.money == 1500
    assert player.sprite_id == @player_sprite_id
    assert player.position == 0
    assert player.properties == []
    assert player.cards == []
    assert player.in_jail === false
    assert player.jail_turns == 0
    assert player.turns_taken == 0
    assert player.rolled === false
  end

  # :OK
  test "new/3 creates a second player with default values", %{second_player: second_player} do
    assert second_player.id == @second_player_id
    assert second_player.name == @second_player_name
    assert second_player.money == 1500
    assert second_player.sprite_id == @second_player_sprite_id
    assert second_player.position == 0
    assert second_player.properties == []
    assert second_player.cards == []
    assert second_player.in_jail === false
    assert second_player.jail_turns == 0
    assert second_player.turns_taken == 0
    assert second_player.rolled === false
  end


  # new(id, name, player_sprite_id) returns correct values : ERROR -> line 127 typo (player.jail_turn's')
  test "Getters for returning correct values (player 1)", %{player: player} do
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

  test "Getters for returning correct values (player 2)", %{second_player: second_player} do
    assert Player.get_id(second_player) == @second_player_id
    assert Player.get_name(second_player) == @second_player_name
    assert Player.get_money(second_player) == 1500
    assert Player.get_sprite_id(second_player) == @second_player_sprite_id
    assert Player.get_position(second_player) == 0
    assert Player.get_properties(second_player) == []
    assert Player.get_cards(second_player) == []
    refute Player.get_in_jail(second_player)
    assert Player.get_jail_turns(second_player) == 0
  end

  # 💸 M O N E Y 💸
  # set_money(__MODULE__.t(), integer()) :: __MODULE__.t(): FAILED
  test "set_money/2 updates first player's money", %{player: player} do
    updated = Player.set_money(player, 100)
    assert updated.money == 100
    assert Player.get_money(player) == 100 # not updated
  end

  test "set_money/2 updates first player's money (0)", %{player: player} do
    updated = Player.set_money(player, 0)
    assert updated.money == 0
    assert Player.get_money(player) == 0 # not updated
  end

  test "set_money/2 updates second player's money (float)", %{second_player: second_player} do
    updated = Player.set_money(second_player, 10.2)
    assert updated.money == 10.2
    assert Player.get_money(second_player) == 10.2 # not updated
  end

  test "set_money/2 updates second player's money (negative)", %{second_player: second_player} do
    updated = Player.set_money(second_player, -10)
    assert updated.money == -10
    assert Player.get_money(second_player) == -10 # not updated
  end

  # add_money(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  # Assume both players starting with the default money (1500)
  test "add_money/2 increases first player's money", %{player: player} do
    updated = Player.add_money(player, 200)
    assert updated.money == 1700
  end

  test "add_money/2 increases first player's money(0)", %{player: player} do
    updated = Player.add_money(player, 0)
    assert updated.money == 1700 # not updated
  end

  test "add_money/2 increases second player's money(-10)", %{second_player: second_player} do
    updated = Player.add_money(second_player, -200)
    assert updated.money == 1300
  end

  test "add_money/2 increases second player's money(0.52)", %{second_player: second_player} do
    updated = Player.add_money(second_player, 0.52)
    assert updated.money == 1300.52
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

  # move(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  # Integer.mod/2 to wrap around the board, limit is set by the @board_size (40) constant
  test "move/2 wraps around board size", %{player: player} do
    # When the number is over 40
    moved = Player.move(player, 42)
    assert moved.position == 2
  end

  # J A I L  L O G I C
  # set_in_jail(__MODULE__.t(), boolean()) :: __MODULE__.t(): OK
  test "set_in_jail/2 sets jail status", %{player: player} do
    updated = Player.set_in_jail(player, true)
    assert updated.in_jail
  end

  # set_jail_turn(__MODULE__.t(), integer()) :: __MODULE__.t(): OK
  test "set_jail_turn/2 sets jail turns", %{player: player} do
    updated = Player.set_jail_turn(player, 2)
    assert updated.jail_turns == 2
  end

  # P R O P E R T Y
  # add_property(__MODULE__.t(), %GameObjects.Property{}) :: __MODULE__.t(): OK
  test "add_property/2 adds a property", %{player: player} do
    property = %GameObjects.Property{name: "West End"}
    updated = Player.add_property(player, property)
    assert updated.properties == [property]
  end

  # C A R D
  # add_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t(): OK
  test "add_card/2 adds a card", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    updated = Player.add_card(player, card)
    assert updated.cards == [card]
  end

  # remove_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t(): OK
  test "remove_card/2 removes a card", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    player_with_card = Player.add_card(player, card)
    updated = Player.remove_card(player_with_card, card)
    assert updated.cards == []
  end

end
