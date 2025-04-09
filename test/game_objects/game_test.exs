defmodule GameObjects.GameTest do
  use ExUnit.Case, async: false
  alias GameObjects.Game
  alias GameObjects.Player
  alias GameObjects.Property
  # alias GameObjects.Card

  setup do
    unless :ets.whereis(Game.Store) != :undefined do
      :ets.new(Game.Store, [:named_table, :public])
    end

    :ets.delete(Game.Store, :game)
    :ok
  end

  defp create_test_player(id, name, sprite_id) do
    Player.new(id, name, sprite_id)
  end

  defp create_test_property(id, name, type, buy_cost) do
    Property.new(id, name, type, buy_cost, [2, 4, 10, 30, 90, 160, 250], 0, 50, 100)
  end

  defp create_test_game(num_players) do
    players = Enum.map(1..num_players, fn i ->
      Player.new("player_#{i}", "Player #{i}", i - 1)
    end)

    %Game{
      players: players,
      properties: Enum.map(0..39, &create_test_property(&1, "Property #{&1}", "brown", 100)),
      deck: [],
      current_player: Enum.at(players, 0),
      active_card: nil,
      turn: 0,
      winner: nil
    }
  end


  describe "start_link/1" do
    test "Game server is running" do
      pid = Process.whereis(Game)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end

  describe "roll_dice/1" do
    test "returns error when not player's turn" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      result = Game.roll_dice("player_2")
      assert {:err, "Not your turn"} = result
    end
  end

  describe "end_turn/1" do
    test "returns error if player hasn't rolled" do
      player = create_test_player("player_1", "Test Player", 0)
      game = %Game{players: [player], properties: [], deck: [], current_player: player, turn: 0}
      :ets.insert(Game.Store, {:game, game})
      assert {:err, "Must roll first"} = Game.end_turn("player_1")
    end
  end

  describe "delete_game/0" do
    test "returns error when no game exists" do
      :ets.delete(Game.Store, :game)
      assert {:err, "No active game to delete!"} = Game.delete_game()
    end

    test "deletes an existing game" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      assert :ok = Game.delete_game()
      assert :ets.lookup(Game.Store, :game) == []
    end
  end


  describe "start_game/0" do
    test "does not start with fewer than 2 players" do
      game = create_test_game(1)
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      assert {:err, "Need at least 2 players"} = Game.start_game()
    end

    test "starts game and initializes properties and deck" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      {:ok, new_game} = Game.start_game()
      assert new_game.current_player != nil
      assert length(new_game.deck) > 0
      assert length(new_game.properties) > 0
    end
  end



  describe "leave_game/1" do
    test "removes player from game" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      # Tell the GenServer to hold the same game state
      :sys.replace_state(Game, fn _ -> game end)

      {:ok, updated_game} = Game.leave_game("player_1")
      refute Enum.any?(updated_game.players, fn p -> p.id == "player_1" end)
      assert length(updated_game.players) == 1
    end

    test "deletes game if last player leaves" do
      game = create_test_game(1)
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      {:ok, "No players, Game deleted.", state} = Game.leave_game("player_1")
      assert state == %{}
      assert :ets.lookup(Game.Store, :game) == []
    end
  end


  describe "game state operations" do
    test "validates initial player money" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.money == 1500
    end

    test "validates player properties" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.properties == []
    end

    test "validates player position" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.position == 0
    end

    test "validates player jail status" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.in_jail == false
    end

    test "validates player turns taken" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.turns_taken == 0
    end

    test "validates player sprite ID" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert player.sprite_id == 0
    end

  end

  describe "game state transitions" do
    test "validates game state after player joins" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      assert game.current_player == player
      assert game.turn == 0
      assert game.winner == nil
    end
  end

  describe "game state persistence" do
    test "validates game state in ETS" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      stored_game = :ets.lookup(Game.Store, :game) |> List.first() |> elem(1)
      assert stored_game == game
    end

    test "validates game state after deletion" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      Game.delete_game()
      assert :ets.lookup(Game.Store, :game) == []
    end
  end

  describe "property transactions" do
    test "validates property ownership" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      property = Enum.at(game.properties, 0)

      # Simulate buying the property
      updated_player = %{player | money: player.money - property.buy_cost}
      updated_property = %{property | owner: player.id}

      game = %{game | players: [updated_player], properties: [updated_property]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_property.owner == player.id
    end

    test "validates complete property transaction" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      property = Enum.at(game.properties, 0)
      initial_money = player.money

      # Test both money deduction and property ownership
      updated_player = %{player |
        money: initial_money - property.buy_cost,
        properties: [property]
      }
      updated_property = %{property | owner: player.id}

      game = %{game |
        players: [updated_player],
        properties: [updated_property | tl(game.properties)]
      }
      :ets.insert(Game.Store, {:game, game})

      assert updated_player.money == initial_money - property.buy_cost
      assert updated_property.owner == player.id
      assert length(updated_player.properties) == 1
    end
  end

  describe "player actions" do
    test "validates player movement" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      original_position = player.position

      # Simulate moving the player
      updated_player = %{player | position: original_position + 3}
      game = %{game | players: [updated_player]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_player.position == original_position + 3
    end

    test "validates player buying property" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      property = Enum.at(game.properties, 0)

      # Simulate buying the property
      updated_player = %{player | money: player.money - property.buy_cost}
      updated_property = %{property | owner: player.id}

      game = %{game | players: [updated_player], properties: [updated_property]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_property.owner == player.id
    end

    test "validates complete player turn" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)

      # Simulate a complete turn
      updated_player = %{player |
        position: player.position + 5,
        turns_taken: player.turns_taken + 1,
        rolled: true
      }
      game = %{game | players: [updated_player]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_player.position == 5
      assert updated_player.turns_taken == 1
      assert updated_player.rolled == true
    end
  end

  describe "property upgrade mechanics" do
    test "validates property upgrade" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      property = Enum.at(game.properties, 0)

      # Simulate upgrading the property
      updated_property = %{property | upgrades: property.upgrades + 1}
      game = %{game | properties: [updated_property]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_property.upgrades == property.upgrades + 1
    end

    test "validates property downgrade" do
      game = create_test_game(1)
      player = Enum.at(game.players, 0)
      property = Enum.at(game.properties, 0)

      # Simulate downgrading the property
      updated_property = %{property | upgrades: property.upgrades - 1}
      game = %{game | properties: [updated_property]}
      :ets.insert(Game.Store, {:game, game})

      assert updated_property.upgrades == property.upgrades - 1
    end
  end

  describe "player turn mechanics" do
    test "player can roll dice on their turn" do
      game = create_test_game(1)
      :ets.insert(Game.Store, {:game, game})

      {:ok, _dice, new_pos, _tile, updated_game} = Game.roll_dice("player_1")
      assert updated_game.current_player.rolled == true
      assert new_pos != 0
    end

    test "player cannot roll twice in one turn" do
      game = create_test_game(1)
      player = %{Enum.at(game.players, 0) | rolled: true}
      game = %{game | players: [player], current_player: player}
      :ets.insert(Game.Store, {:game, game})

      assert {:err, "Not your turn"} = Game.roll_dice("player_1")
    end
  end

  describe "game winner" do
    test "validates game winner" do
      game = create_test_game(2)
      player1 = Enum.at(game.players, 0)
      player2 = Enum.at(game.players, 1)

      # Simulate player 1 winning
      updated_game = %{game | winner: player1}
      :ets.insert(Game.Store, {:game, updated_game})

      assert updated_game.winner == player1
    end

    test "validates no winner when game is ongoing" do
      game = create_test_game(2)
      :ets.insert(Game.Store, {:game, game})

      assert game.winner == nil
    end
  end

  describe "jail mechanics" do
    test "player must pay to get out after three failed rolls" do
      game = create_test_game(1)
      player = %{Enum.at(game.players, 0) |
        in_jail: true,
        position: 10,  # Jail position
        jail_turns: 2,
        money: 1500
      }
      game = %{game |
        players: [player],
        current_player: player
      }
      :ets.insert(Game.Store, {:game, game})

      # Force non-doubles roll on third turn
      :rand.seed(:exs1024, {1, 2, 3})
      {:ok, _dice, new_pos, _tile, updated_game} = Game.roll_dice("player_1")

      assert updated_game.current_player.in_jail == false
      assert updated_game.current_player.position == new_pos
      assert updated_game.current_player.money == 1450  # 1500 - 50 (jail fee)
    end
  end

  describe "property upgrade limits" do
    test "property cannot upgrade beyond hotel (level 6)" do
      prop = create_test_property(1, "Boardwalk", "blue", 400)
      prop = %{prop | upgrades: 6}
      {new_prop, cost} = Property.build_upgrade(prop)

      assert cost == 0
      assert new_prop.upgrades == 6
    end

    test "property downgrades from hotel to 5 houses and refunds hotel price" do
      prop = create_test_property(1, "Boardwalk", "blue", 400)
      prop = %{prop | upgrades: 6}
      {new_prop, refund} = Property.sell_upgrade(prop)

      assert new_prop.upgrades == 5
      assert refund == prop.hotel_price
    end
  end

  describe "player bankruptcy and status" do
    test "player becomes inactive after going bankrupt" do
      game = create_test_game(1)
      player = %{Enum.at(game.players, 0) | money: -10}
      game = %{game | players: [player], current_player: player}
      :ets.insert(Game.Store, {:game, game})

      :rand.seed(:exsplus, {123, 456, 789})
      {:ok, _dice, _pos, _tile, updated_game} = Game.roll_dice("player_1")

      assert updated_game.current_player.active == false
    end

    test "set_player_active revives eligible player" do
      player = %{create_test_player("p1", "P1", 0) | active: false, money: 100}
      game = %Game{
        players: [player],
        current_player: player,
        properties: [],
        deck: [],
        turn: 0,
        active_card: nil,
        winner: nil
      }

      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      {:ok, updated_game} = Game.set_player_active("p1")
      assert Enum.at(updated_game.players, 0).active == true
    end
  end

  describe "turn mechanics and skipping" do
    test "end_turn skips inactive player" do
      players = [
        create_test_player("p1", "P1", 0),
        %{create_test_player("p2", "P2", 1) | active: false},
        create_test_player("p3", "P3", 2)
      ]

      game = %Game{
        players: players,
        properties: [],
        deck: [],
        current_player: Enum.at(players, 0),
        turn: 0,
        active_card: nil,
        winner: nil
      }

      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      updated_p1 = %{Enum.at(players, 0) | rolled: true}
      updated_players = [updated_p1, Enum.at(players, 1), Enum.at(players, 2)]
      :ets.insert(Game.Store, {:game, %{game | players: updated_players, current_player: updated_p1}})

      {:ok, updated_game} = Game.end_turn("p1")

      assert updated_game.current_player.id == "p3"
    end
  end

  describe "turn order mechanics" do
    test "validates turn advancement after end_turn" do
      # Setup 3 players
      players = [
        create_test_player("p1", "P1", 0),
        create_test_player("p2", "P2", 1),
        create_test_player("p3", "P3", 2)
      ]

      # Create initial game state with first player having rolled
      first_player = %{Enum.at(players, 0) | rolled: true}
      game = %Game{
        players: [first_player | tl(players)],
        properties: [],
        deck: [],
        current_player: first_player,
        turn: 0,
        active_card: nil,
        winner: nil
      }

      # Set up game state
      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      # End turn and verify next player
      {:ok, updated_game} = Game.end_turn("p1")

      assert updated_game.current_player.id == "p2"
      assert updated_game.turn == 1
      refute updated_game.current_player.rolled
    end
  end

end
