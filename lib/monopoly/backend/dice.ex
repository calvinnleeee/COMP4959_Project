defmodule GameObjects.Dice do
  @moduledoc """
  This represents the Dice that are rolled at the start of each player's turn.
  """

  # Roll and return a tuple of two random integers [1-6]
  def roll() do
    die1 = :rand.uniform(6)
    die2 = :rand.uniform(6)
    {die1, die2}
  end

  # Determine the outcome of a jail roll based on the dice values and the number of attempts
  def jail_roll({d1, d2}, attempt_num) do
    cond do
      d1 == d2 -> {:out_of_jail, {d1, d2}}
      attempt_num >= 3 -> {:failed_to_escape, {d1, d2}}
      true -> {:stay_in_jail, {d1, d2}}
    end
  end

end
