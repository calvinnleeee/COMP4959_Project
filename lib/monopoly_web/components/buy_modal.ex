defmodule MonopolyWeb.Components.BuyModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders a Buy Modal for confirming property purchase.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_buy, :any, default: nil, doc: "JS command or event for buying"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def buy_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="buy-modal-content p-6">
        <h2 class="text-xl font-bold mb-4">Buy Property</h2>
        <p class="mb-6">
          <%= @property.name %> : <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>
        <!-- property image -->
        <div class="flex gap-4">
          <button phx-click="buy_property" class="btn btn-primary">
            Buy
          </button>
          <button phx-click="cancel_buying" class="btn btn-secondary">
            Leave
          </button>
        </div>
      </div>
    </.modal>
    """
  end
end
