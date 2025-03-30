defmodule GameObjects.Player do
  @moduledoc """
  This module represents a player and their attributes.

  properties field is a list of properites the player owns.

  id is the session id of the player.
  """

  defstruct [:id, :name, :money, :sprite_id, :position, :cards, :in_jail, :jail_turns, :turns_taken]

end
