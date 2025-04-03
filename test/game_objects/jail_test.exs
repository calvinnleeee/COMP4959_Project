defmodule GameObjects.JailTest do
  use ExUnit.Case
  alias GameObjects.Dice

  describe "check_for_jail function" do
    test "detects 3 consecutive doubles" do
      # Simulating two previous rolls both being doubles
      previous_rolls = [
        {{6, 6}, 12, true},  # Most recent roll
        {{4, 4}, 8, true}    # Second most recent roll
      ]

      # Third roll is also doubles
      current_roll = {{5, 5}, 10, true}

      # Should detect jail condition
      assert Dice.check_for_jail(previous_rolls, current_roll) == true
    end

    test "doesn't detect jail condition with non-consecutive doubles" do
      # Most recent roll is not doubles
      previous_rolls = [
        {{2, 3}, 5, false},  # Most recent roll
        {{4, 4}, 8, true}    # Second most recent roll
      ]

      # Current roll is doubles
      current_roll = {{5, 5}, 10, true}

      # Should not detect jail condition
      assert Dice.check_for_jail(previous_rolls, current_roll) == false
    end

    test "doesn't detect jail condition with only two consecutive doubles" do
      # Only one previous doubles roll in history
      previous_rolls = [
        {{4, 4}, 8, true}  # Most recent roll is doubles
      ]

      # Current roll is also doubles
      current_roll = {{5, 5}, 10, true}

      # Should not detect jail condition (only two consecutive doubles)
      assert Dice.check_for_jail(previous_rolls, current_roll) == false
    end
  end
end
