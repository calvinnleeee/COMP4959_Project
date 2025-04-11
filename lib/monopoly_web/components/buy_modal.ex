defmodule MonopolyWeb.Components.BuyModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents
  alias Phoenix.LiveView.JS

  @doc """
  Renders a Buy Modal for confirming property purchase.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_buy, :any, default: nil, doc: "JS command or event for buying"
  attr :on_cancel, JS, default: %JS{}, doc: "JS command for cancel action"

  def buy_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={%JS{}}>
      <div class="buy-modal-content p-6 z-10">
        <h2 class="text-xl font-bold mb-4">Buy Property</h2>
        <p class="mb-6">
          <%= @property.name %> : <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>
        <div class="flex justify-between gap-4">
          <button phx-click="buy_prop" class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600">
            Buy
          </button>
          <button phx-click="cancel_buying" class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600">
            Leave
          </button>
        </div>
      </div>
    </.modal>
    """
  end
end
