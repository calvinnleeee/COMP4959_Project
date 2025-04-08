defmodule MonopolyWeb.Components.BuyModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  TODO buy property modal is shown underneath the dashboard (z-index needs to be updated)
  TODO when buy modal pops up, i can press leave to not buy it, end turn, then the turn counter doesn't increment (next player never gets their turn ???)
  Renders a Buy Modal for confirming property purchase.
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_buy, :any, default: nil, doc: "JS command or event for buying"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def buy_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <%!-- comment out for design adjustment: <div class="buy-modal-content p-6"> --%>
      <div class={"modal buy " <> @class}>
        <h2 class="text-xl font-bold mb-4">Buy Property</h2>
        <p class="mb-6">
          <%= @property.name %> : <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>
        <!-- property image -->
        <div class="flex gap-4">
          <button phx-click="buy_prop" class="btn btn-primary">
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
