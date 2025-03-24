defmodule GameObjects.Property do
  @moduledoc """
  This modules represents Properties, which are houses and hotels that can be bought and placed on Square.

  owner field is either nil or a pid
  type field refers to either "house" or "hotel"

  Owner is the id of the player that owns the property.
  """

  defstruct [:id, :name, :type, :buy_cost, :rent_cost, :owner]


end
