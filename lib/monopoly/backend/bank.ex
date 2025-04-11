defmodule GameObjects.Bank do
  @moduledoc """
  This module represents the Bank (non-player) that handles auctions and financial services.

  properties field is a list of properites the player owns.
  """

  @derive Jason.Encoder
  defstruct [:money_amount, :properties]
end
