defmodule Monopoly.AuctionLiveTest do
  use Monopoly.DataCase

  alias Monopoly.AuctionLive

  describe "bids" do
    alias Monopoly.AuctionLive.Bid

    import Monopoly.AuctionLiveFixtures

    @invalid_attrs %{player: nil, bid_price: nil, property_prices: nil}

    test "list_bids/0 returns all bids" do
      bid = bid_fixture()
      assert AuctionLive.list_bids() == [bid]
    end

    test "get_bid!/1 returns the bid with given id" do
      bid = bid_fixture()
      assert AuctionLive.get_bid!(bid.id) == bid
    end

    test "create_bid/1 with valid data creates a bid" do
      valid_attrs = %{player: "some player", bid_price: 42, property_prices: "some property_prices"}

      assert {:ok, %Bid{} = bid} = AuctionLive.create_bid(valid_attrs)
      assert bid.player == "some player"
      assert bid.bid_price == 42
      assert bid.property_prices == "some property_prices"
    end

    test "create_bid/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AuctionLive.create_bid(@invalid_attrs)
    end

    test "update_bid/2 with valid data updates the bid" do
      bid = bid_fixture()
      update_attrs = %{player: "some updated player", bid_price: 43, property_prices: "some updated property_prices"}

      assert {:ok, %Bid{} = bid} = AuctionLive.update_bid(bid, update_attrs)
      assert bid.player == "some updated player"
      assert bid.bid_price == 43
      assert bid.property_prices == "some updated property_prices"
    end

    test "update_bid/2 with invalid data returns error changeset" do
      bid = bid_fixture()
      assert {:error, %Ecto.Changeset{}} = AuctionLive.update_bid(bid, @invalid_attrs)
      assert bid == AuctionLive.get_bid!(bid.id)
    end

    test "delete_bid/1 deletes the bid" do
      bid = bid_fixture()
      assert {:ok, %Bid{}} = AuctionLive.delete_bid(bid)
      assert_raise Ecto.NoResultsError, fn -> AuctionLive.get_bid!(bid.id) end
    end

    test "change_bid/1 returns a bid changeset" do
      bid = bid_fixture()
      assert %Ecto.Changeset{} = AuctionLive.change_bid(bid)
    end
  end
end
