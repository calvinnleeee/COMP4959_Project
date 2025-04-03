defmodule GameObjects.GameTest do
  use ExUnit.Case, async: true
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
      state: nil,
      players: players,
      properties: Enum.map(0..39, &create_test_property(&1, "Property #{&1}", "brown", 100)),
      deck: [],
      current_player: Enum.at(players, 0),
      active_card: nil,
      turn: 0
    }
  end


  describe "start_link/1" do
    test "Game server is running" do
      pid = Process.whereis(Game)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end

  describe "join_game/1" do
    test "creates a new game when one doesn't exist" do
      session_id = "new_player_session"
      :ets.delete(Game.Store, :game)
      {:ok, game} = Game.join_game(session_id)
      assert length(game.players) == 1
    end

    test "adds player to existing game" do
      game = create_test_game(1)
      :ets.insert(Game.Store, {:game, game})
      {:ok, updated_game} = Game.join_game("player_2")
      assert length(updated_game.players) == 2
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

  describe "take_turn/2" do
    setup do
      # Clean ETS and reset state only
      :ets.delete(Game.Store, :game)

      :ok
    end

    test "player pays rent on owned property" do
      player = create_test_player("renter", "Renter", 1)
      owner = create_test_player("owner", "Owner", 0)

      property = create_test_property(5, "Rent Tile", "brown", 60)
      property = %{property | owner: owner}

      game = %Game{
        players: [player, owner],
        properties: [property],
        current_player: player,
        deck: [],
        turn: 0
      }

      :ets.insert(Game.Store, {:game, game})
      :sys.replace_state(Game, fn _ -> game end)

      {:ok, updated_game} = Game.take_turn("renter", property)

      updated_player = Enum.find(updated_game.players, &(&1.id == "renter"))
      updated_owner = Enum.find(updated_game.players, &(&1.id == "owner"))

      assert updated_player.money < 1500
      assert updated_owner.money > 1500
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

end
