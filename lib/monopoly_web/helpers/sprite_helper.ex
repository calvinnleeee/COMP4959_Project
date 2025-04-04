defmodule MonopolyWeb.Helpers.SpriteHelper do
  @moduledoc """
  Maps sprite IDs to image filenames for display purposes.
  """

  @sprite_map %{
    0 => "Piece_Ant.png",
    1 => "Piece_Boat.png",
    2 => "Piece_Boot.png",
    3 => "Piece_Car.png",
    4 => "Piece_Dog.png",
    5 => "Piece_Thimble.png",
    6 => "Piece_TopHat.png",
    7 => "Piece_Wheelbarrow.png"
  }

  def get_sprite_filename(sprite_id) do
    Map.get(@sprite_map, sprite_id, "Piece_Ant.png")
  end
end
