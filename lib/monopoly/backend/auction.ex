defmodule GameObjects.Auction do
  @moduledoc """
  This module represents the "Round Robin" style auction house,
  each player places bid, by end highest wins the auction.

  'bids' are a map of key-value pairs. With the 'pid' being the key and the value is 'bid_amount'.
  """
  @derive Jason.Encoder
  defstruct [:auction_propery, :highest_bid, :current_bidder, :bids]

end
