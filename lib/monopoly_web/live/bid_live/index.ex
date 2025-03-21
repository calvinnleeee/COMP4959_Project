defmodule MonopolyWeb.BidLive.Index do
  use MonopolyWeb, :live_view

  alias Monopoly.AuctionLive
  alias Monopoly.AuctionLive.Bid

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :bids, AuctionLive.list_bids())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Bid")
    |> assign(:bid, AuctionLive.get_bid!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Bid")
    |> assign(:bid, %Bid{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Bids")
    |> assign(:bid, nil)
  end

  @impl true
  def handle_info({MonopolyWeb.BidLive.FormComponent, {:saved, bid}}, socket) do
    {:noreply, stream_insert(socket, :bids, bid)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bid = AuctionLive.get_bid!(id)
    {:ok, _} = AuctionLive.delete_bid(bid)

    {:noreply, stream_delete(socket, :bids, bid)}
  end
end
