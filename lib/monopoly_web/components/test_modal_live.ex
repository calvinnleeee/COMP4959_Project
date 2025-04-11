defmodule MonopolyWeb.TestModalLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.Components.BuyModal
  import MonopolyWeb.CoreComponents

  def mount(_params, _session, socket) do
    property = %{name: "Boardwalk", buy_cost: 400}
    {:ok, assign(socket, show_buy_modal: true, current_property: property)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.buy_modal id="buy-modal" show={@show_buy_modal} property={@current_property}
        on_cancel={hide_modal("buy-modal")}/>
    </div>
    """
  end
end
