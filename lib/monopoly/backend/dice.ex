defmodule GameObjects.Dice do
  @moduledoc """
  This represents the Dice that are rolled at the start of each player's turn.
  """

  # Roll and return a tuple with: individual dice values as a tuple, sum of both dice, and whether it's doubles
  def roll() do
    die1 = :rand.uniform(6)
    die2 = :rand.uniform(6)
    sum = die1 + die2
    is_doubles = die1 == die2

    {{die1, die2}, sum, is_doubles}
  end

  # check if a player should go to jail based on consecutive doubles
<<<<<<< HEAD
  def check_for_jail(turns_taken, is_doubles) do
    is_doubles && turns_taken > 2
=======
  def check_for_jail(previous_rolls, {_dice, _sum, is_doubles}) do
    recent_doubles =
      previous_rolls
      |> Enum.take(2)
      |> Enum.all?(fn {_dice, _sum, doubles} -> doubles end)

    is_doubles and recent_doubles and length(previous_rolls) >= 2
>>>>>>> 0d9b470 (added jail_roll handle_event for jail logic and added backend code for testing)
  end

  # Determine the outcome of a jail roll based on the dice values and the number of attempts
  def jail_roll(jail_turns) do
    {{die1, die2} = dice, sum, is_doubles} = roll()

    cond do
      is_doubles -> {:out_of_jail, dice, sum}
      jail_turns >= 2 -> {:failed_to_escape, dice, sum}
      true -> {:stay_in_jail, dice, sum}
    end
  end
end
