defmodule MonopolyWeb.Helpers.SpriteHelper do
  @moduledoc """
  Maps sprite IDs to image filenames for display purposes.
  """


  def get_sprite_filename(sprite_id) do
    "/images/sprites/" <> sprite_id
  end
end
