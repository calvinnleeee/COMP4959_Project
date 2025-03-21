defmodule MonopolyWeb.BidLiveTest do
  use MonopolyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Monopoly.AuctionLiveFixtures

  @create_attrs %{player: "some player", bid_price: 42, property_prices: "some property_prices"}
  @update_attrs %{player: "some updated player", bid_price: 43, property_prices: "some updated property_prices"}
  @invalid_attrs %{player: nil, bid_price: nil, property_prices: nil}

  defp create_bid(_) do
    bid = bid_fixture()
    %{bid: bid}
  end

  describe "Index" do
    setup [:create_bid]

    test "lists all bids", %{conn: conn, bid: bid} do
      {:ok, _index_live, html} = live(conn, ~p"/bids")

      assert html =~ "Listing Bids"
      assert html =~ bid.player
    end

    test "saves new bid", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bids")

      assert index_live |> element("a", "New Bid") |> render_click() =~
               "New Bid"

      assert_patch(index_live, ~p"/bids/new")

      assert index_live
             |> form("#bid-form", bid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bid-form", bid: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bids")

      html = render(index_live)
      assert html =~ "Bid created successfully"
      assert html =~ "some player"
    end

    test "updates bid in listing", %{conn: conn, bid: bid} do
      {:ok, index_live, _html} = live(conn, ~p"/bids")

      assert index_live |> element("#bids-#{bid.id} a", "Edit") |> render_click() =~
               "Edit Bid"

      assert_patch(index_live, ~p"/bids/#{bid}/edit")

      assert index_live
             |> form("#bid-form", bid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bid-form", bid: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bids")

      html = render(index_live)
      assert html =~ "Bid updated successfully"
      assert html =~ "some updated player"
    end

    test "deletes bid in listing", %{conn: conn, bid: bid} do
      {:ok, index_live, _html} = live(conn, ~p"/bids")

      assert index_live |> element("#bids-#{bid.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#bids-#{bid.id}")
    end
  end

  describe "Show" do
    setup [:create_bid]

    test "displays bid", %{conn: conn, bid: bid} do
      {:ok, _show_live, html} = live(conn, ~p"/bids/#{bid}")

      assert html =~ "Show Bid"
      assert html =~ bid.player
    end

    test "updates bid within modal", %{conn: conn, bid: bid} do
      {:ok, show_live, _html} = live(conn, ~p"/bids/#{bid}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Bid"

      assert_patch(show_live, ~p"/bids/#{bid}/show/edit")

      assert show_live
             |> form("#bid-form", bid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#bid-form", bid: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/bids/#{bid}")

      html = render(show_live)
      assert html =~ "Bid updated successfully"
      assert html =~ "some updated player"
    end
  end
end
