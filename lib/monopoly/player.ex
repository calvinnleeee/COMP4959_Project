defmodule GameObjects.Player do
  @moduledoc """
  This module represents a player and their attributes.

  properties field is a list of properites the player owns.
  """

  defstruct [:name, :pid, :web_socket, :money, :sprite_id, :position, :in_jail, :jail_turns, :properties]


end
