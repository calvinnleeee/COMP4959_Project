defmodule MonopolyWeb.GameLive do
  use MonopolyWeb, :live_view

  # TODO when property already bought
  # TODO need place bid logic @handle_event("place_bid")

  def mount(_params, _session, socket) do
    # init status
    {:ok, assign(socket, show_modal: false, modal_type: nil, auction: %{}, property: %{})}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Monopoly Game</h1>

      <!-- Game board and other UI if needed.. user dashboard? -->

      <%= if @show_modal do %>
        <.live_component @socket, MonopolyWeb.ModalComponent,
              id: modal,
              inner_content: render_modal(@modal_type, assigns) />
      <% end %>
    </div>
    """
  end

  # false alarm; used in ^inner_content
  defp render_modal(:property_buy, assigns) do
    ~H"""
    <div>
      <p>For sale property</p>
      <p>Price: $000</p>
      <p>Card image of property info</p>
      <button phx-click="buy_property">Buy</button>
      <button phx-click="decline_property">Auction</button>
    </div>
    """
  end

  defp render_modal(:auction, assigns) do
    ~H"""
    <div>
      <p>Welcome to the auction!</p>
      <form phx-submit="place_bid">
        <input type="number" name="bid" placeholder="Bid amount" />
        <button type="submit">Bid</button>
      </form>
    </div>
    """
  end

  # pattern matching event of buy || decline || auction bid
  # need pubsub
  # ex) Phoenix.PubSub.broadcast(Monopoly.PubSub, "game:updates", %{event: "show_modal", modal_type: :property_buy})
  def handle_event("buy_property", _params, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end
  def handle_event("decline_property", _params, socket) do
    {:noreply, assign(socket, modal_type: :auction)}
  end
  def handle_event("place_bid", %{"bid" => bid_amount}, socket) do
    # map bid amount
    IO.puts(bid_amount) # need place bid logic

    {:noreply, socket}
  end
end
