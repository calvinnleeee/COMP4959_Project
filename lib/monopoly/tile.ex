defmodule GameObjects.Square do
  @moduledoc """
  Square objects are tiles on the Board, each square has attributes and

  properties field is a map[type]number. TODO: shouldn't this just be a map of Property structs?
  """

  defstruct [:id, :name, :type, :color_set, :properties]

end
