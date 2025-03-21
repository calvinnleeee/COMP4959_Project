defmodule Monopoly.AuctionLive.Bid do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bids" do
    field :player, :string
    field :bid_price, :integer
    field :property_prices, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bid, attrs) do
    bid
    |> cast(attrs, [:player, :bid_price, :property_prices])
    |> validate_required([:player, :bid_price, :property_prices])
  end
end
