defmodule GameObjects.PlayerTest do
  # Unit tests for player.ex (almost done)
  #
  # TODO(?)
  #   - Save logic after a players' status change (Setters doesn't work) -> Check my test logic
  #   - Change test names into meaningful ones
  #   - Double check if the way raising error is correct

  use ExUnit.Case
  alias GameObjects.Player

  # Test player 1
  # OK
  @player_id "albert123"
  @player_name "Albert"
  @player_sprite_id 1

  # Test player 2 with funcky string
  # OK
  @second_player_id "123Inez😉"
  @second_player_name "⑅*ॱ˖•. ·͙*̩̩͙˚̩̥̩ì̖̗n̖̹̍è̖̤z̖͎̥̩̥̏̀̀*̩̩͙‧͙ .•˖ॱ*⑅"
  @second_player_sprite_id 3285

  # Basic setup test for hardcoded test
  # OK
  setup do
    player = Player.new(@player_id, @player_name, @player_sprite_id)
    second_player = Player.new(@second_player_id, @second_player_name, @second_player_sprite_id)
    %{player: player, second_player: second_player}
  end

  # new(id, name, player_sprite_id) creates player with default value
  # OK
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
  # OK
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

  # :OK
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
  # set_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  # :ERROR
  test "set_money/2 updates first player's money", %{player: player} do
    updated = Player.set_money(player, 100)
    assert updated.money == 100
    assert Player.get_money(player) == 100 # not updated
  end

  # :ERROR
  test "set_money/2 updates first player's money (0)", %{player: player} do
    updated = Player.set_money(player, 0)
    assert updated.money == 0
    assert Player.get_money(player) == 0 # not updated
  end

  # :ERROR
  test "set_money/2 updates second player's money (float)", %{second_player: second_player} do
    updated = Player.set_money(second_player, 10.2)
    assert updated.money == 10.2
    assert Player.get_money(second_player) == 10.2 # not updated
  end

  # :ERROR
  test "set_money/2 updates second player's money (negative)", %{second_player: second_player} do
    updated = Player.set_money(second_player, -10)
    assert updated.money == -10
    assert Player.get_money(second_player) == -10 # not updated
  end

  # add_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  # Assume both players starting with the default money (1500)
  # :OK
  test "add_money/2 increases first player's money", %{player: player} do
    updated = Player.add_money(player, 200)
    assert updated.money == 1700
  end

  # :ERROR
  test "add_money/2 increases first player's money(0)", %{player: player} do
    updated = Player.add_money(player, 0)
    assert updated.money == 1700 # not updated
  end

  # :OK
  test "add_money/2 increases second player's money(-10)", %{second_player: second_player} do
    updated = Player.add_money(second_player, -200)
    assert updated.money == 1300
  end

  # :ERROR
  test "add_money/2 increases second player's money(0.52)", %{second_player: second_player} do
    updated = Player.add_money(second_player, 0.52)
    assert updated.money == 1300.52
  end

  # lose_money(__MODULE__.t(), integer()) :: __MODULE__.t()
  # Assume both players starting from the default value (1500)
  # :OK
  test "lose_money/2 reduces the first player's money", %{player: player} do
    updated = Player.lose_money(player, 300)
    assert updated.money == 1200
    assert Player.get_money(player)
  end

  # :ERROR
  test "lose_money/2 reduces the first player's money (-300)", %{player: player} do
    updated = Player.lose_money(player, -300)
    assert updated.money == 1500 # not updated
    assert Player.get_money(player) # result: 1800
  end

  # :OK
  test "lose_money/2 reduces the second player's money (0)", %{second_player: second_player} do
    # Assume starting from 1500
    updated = Player.lose_money(second_player, 0)
    assert updated.money == 1500
    assert Player.get_money(second_player)
  end

  # :OK
  test "lose_money/2 reduces the second player's money (0.50)", %{second_player: second_player} do
    updated = Player.lose_money(second_player, 0.50)
    assert updated.money == 1499.50
    assert Player.get_money(second_player)
  end

  # @spec lose_money(__MODULE__.t(), __MODULE__.t(), integer()) :: {__MODULE__.t(), __MODULE__.t()}
  # :OK
  test "lose_money/3 transfers money between players", %{player: player, second_player: second_player} do
    # Assume money set up as the default (1500)
    {p1_after, p2_after} = Player.lose_money(player, second_player, 500)

    assert p1_after.money == 1000
    assert p2_after.money == 2000
  end

  # :OK
  test "lose_money/3 transfers money between players (0)", %{player: player, second_player: second_player} do
    # Assume money set up as the default (1500)
    {p1_after, p2_after} = Player.lose_money(player, second_player, 0)

    assert p1_after.money == 1500
    assert p2_after.money == 1500
  end

  # :OK
  test "lose_money/3 transfers money between players (-100)", %{player: player, second_player: second_player} do
    # Assume money set up as the default (1500)
    {p1_after, p2_after} = Player.lose_money(player, second_player, -100)

    assert p1_after.money == 1600
    assert p2_after.money == 1400
  end

  # :OK
  test "lose_money/3 transfers money between players (0.01)", %{player: player, second_player: second_player} do
    # Assume money set up as the default (1500)
    {p1_after, p2_after} = Player.lose_money(player, second_player, 0.01)

    assert p1_after.money == 1499.99
    assert p2_after.money == 1500.01
  end

  # :ERROR
  test "lose_money/3 transfers money between a legit player and unknown player(nil)", %{player: player} do
    fake_player = %{id: nil, money: 0}

    # Expected exception KeyError but nothing was raised
    assert_raise KeyError, fn ->
      Player.lose_money(player, fake_player, 100)
    end
  end


  # 🏃 M O V E  L O G I C 🏃
  # set_position(__MODULE__.t(), integer()) :: __MODULE__.t()
  # :OK
  test "set_position/2 sets the position", %{player: player} do
    updated = Player.set_position(player, 10)
    assert updated.position == 10
  end

  # :OK
  test "set_position/2 sets the position (0)", %{player: player} do
    updated = Player.set_position(player, 0)
    assert updated.position == 0
  end

  # :OK
  test "set_position/2 sets the position (-10)", %{player: player} do
    updated = Player.set_position(player, -10)
    assert updated.position == -10
  end

  # :OK
  test "set_position/2 sets the position (0.001)", %{player: player} do
    updated = Player.set_position(player, 0.001)
    assert updated.position == 0.001
  end

  # move(__MODULE__.t(), integer()) :: __MODULE__.t()
  # Integer.mod/2 to wrap around the board, limit is set by the @board_size (40) constant

  # :OK
  test "move/2 wraps around board size", %{player: player} do
    # When the number is over 40
    moved = Player.move(player, 42)
    assert moved.position == 2
  end

  # :OK
  test "move/2 with a positive integer", %{player: player} do
    moved = Player.move(player, 3)
    assert moved.position == 3
  end

  # :OK
  test "move/2 with a negative integer", %{player: player} do
    moved = Player.move(player, -10)
    assert moved.position == 30
  end

  # 🚧 J A I L  L O G I C 🚧
  # set_in_jail(__MODULE__.t(), boolean()) :: __MODULE__.t()
  # : OK
  test "set_in_jail/2 sets jail status", %{player: player} do
    updated = Player.set_in_jail(player, true)
    assert updated.in_jail
  end

  # :OK
  test "set_in_jail/2 does bit cgabge anything if already in jail", %{player: player} do
    jailed = Player.set_in_jail(player, true)
    still_jailed = Player.set_in_jail(jailed, true) # Maybe we can add warning message?

    assert still_jailed.in_jail == true
    assert jailed == still_jailed
  end

  # :ERROR
  test "set_in_jail/2 with nil raises ArgumentError" do
    # maybe we can add  set_in_jail(nil, _in_jail), do: raise ArgumentError, "Invalid player: nil" or set_in_jail(%__MODULE__{} = player, in_jail), do: %{player | in_jail: in_jail}
    assert_raise ArgumentError, fn ->
      Player.set_in_jail(nil, true)
    end
  end

  # set_jail_turn(__MODULE__.t(), integer()) :: __MODULE__.t()
  # : OK
  test "set_jail_turn/2 sets jail turns", %{player: player} do
    updated = Player.set_jail_turn(player, 2)
    assert updated.jail_turns == 2
  end

  # : ERROR Nothing was raised
  test "set_jail_turn/2 fails with non-numbers", %{player: player} do
    assert_raise ArgumentError, fn ->
      Player.set_jail_turn(player, "abc")
    end
  end

  # 🏡 P R O P E R T Y 🏡
  # add_property(__MODULE__.t(), %GameObjects.Property{}) :: __MODULE__.t()
  # :OK
  test "add_property/2 adds a property", %{player: player} do
    property = %GameObjects.Property{name: "West End"}
    updated = Player.add_property(player, property)
    assert updated.properties == [property]
  end

  # :ERROR
  # def add_property(player, tile) do
  #%{player | properties: Enum.concat(get_properties(player), [tile])}
  #end
  test "add_property/2 allows duplicate properties", %{player: player} do
    property = %GameObjects.Property{name: "West End"}

    player = Player.add_property(player, property)
    updated = Player.add_property(player, property)

    assert updated.properties == [property, property]
  end

  # :ERROR
  test "add_property/2 doesn't allow to have empty string name", %{player: player} do
    property = %GameObjects.Property{name: ""}
    updated = Player.add_property(player, property)
    assert updated.properties == [property]
  end

  # :OK
  test "add_property/2 with numbers", %{player: player} do
    property = %GameObjects.Property{name: 12123}
    updated = Player.add_property(player, property)
    assert updated.properties == [property]
  end

    # :OK
  test "add_property/2 with crazy string", %{player: player} do
    property = %GameObjects.Property{name: "🏡.•°¤*(¯`★´¯)*¤°   🎀  𝓅𝑒𝓃𝓉𝒽☯𝓊𝓈𝑒  🎀   °¤*)¯´★`¯(*¤°•."}
    updated = Player.add_property(player, property)
    assert updated.properties == [property]
  end

  # 🃏 C A R D 🃏
  # add_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t()
  # :OK
  test "add_card/2 adds a card", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    updated = Player.add_card(player, card)
    assert updated.cards == [card]
  end

  # :OK
  test "add_card/2 stacks multiple cards", %{player: player} do
    card1 = %GameObjects.Card{type: :get_out_of_jail}
    card2 = %GameObjects.Card{type: :advance_to_go}

    updated = player
              |> Player.add_card(card1)
              |> Player.add_card(card2)

    assert updated.cards == [card2, card1]
  end

  # :OK
  test "add_card/2 allows duplicate cards", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    updated = player
              |> Player.add_card(card)
              |> Player.add_card(card)

    assert updated.cards == [card, card]
  end

  # :OK
  test "add_card/2 with nil adds nil to cards", %{player: player} do
    updated = Player.add_card(player, nil)
    assert updated.cards == [nil]
  end

  # :ERROR nothing was raised
  test "add_card/2 with invalid card type (string) raises error", %{player: player} do
    assert_raise FunctionClauseError, fn ->
      Player.add_card(player, "not a card")
    end
  end

  # remove_card(__MODULE__.t(), %GameObjects.Card{}) :: __MODULE__.t()
  # :OK
  test "remove_card/2 removes a card", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    player_with_card = Player.add_card(player, card)
    updated = Player.remove_card(player_with_card, card)
    assert updated.cards == []
  end

  # :OK
  test "remove_card/2 does nothing if card is not found", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}
    not_owned_card = %GameObjects.Card{type: :advance_to_go}

    player_with_card = Player.add_card(player, card)
    updated = Player.remove_card(player_with_card, not_owned_card)

    assert updated.cards == [card]
  end

  # :OK
  test "remove_card/2 only removes one instance if duplicates exist", %{player: player} do
    card = %GameObjects.Card{type: :get_out_of_jail}

    player_with_cards =
      player
      |> Player.add_card(card)
      |> Player.add_card(card)

    updated = Player.remove_card(player_with_cards, card)

    assert updated.cards == [card]  # One left(???)
  end
end
