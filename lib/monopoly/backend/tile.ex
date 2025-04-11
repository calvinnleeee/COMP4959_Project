defmodule GameObjects.Square do
  @moduledoc """
  Square objects are tiles on the Board, each square has attributes and

  properties field is a map[type]number. TODO: shouldn't this just be a map of Property structs?

  #TODO: ONLY FOR REFERENCE, Translate this into a static JSON file for ALL the tiles
  """

  @derive Jason.Encoder
  defstruct [:id, :name, :type, :color_set, :properties]


end
