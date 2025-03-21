defmodule Monopoly.AuctionLiveFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Monopoly.AuctionLive` context.
  """

  @doc """
  Generate a bid.
  """
  def bid_fixture(attrs \\ %{}) do
    {:ok, bid} =
      attrs
      |> Enum.into(%{
        bid_price: 42,
        player: "some player",
        property_prices: "some property_prices"
      })
      |> Monopoly.AuctionLive.create_bid()

    bid
  end
end
