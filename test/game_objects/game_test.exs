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

  
end
