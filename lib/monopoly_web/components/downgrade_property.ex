defmodule MonopolyWeb.Components.DowngradeProperty do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders an Downgrade Property Modal to sell the property the player owned.
  Players must sell all houses of the full set of property before they can sell the property.
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_buy, :any, default: nil, doc: "JS command or event for buying"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def downgrade_prop_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <%!-- comment out for design adjustment: <div class="buy-modal-content p-6"> --%>

      <%!-- :downgrade_property,
      but we will need to include selling the property itself in that function.
      players will have the ability to sell their house and their property,
      but they must sell all houses of the full set of property before they can sell the property --%>

      <div class={"modal buy " <> @class}>
        <h2 class="text-xl font-bold mb-4">Sell Property</h2>
        <p class="mb-6">
          <%= @property.name %> : <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>
        <!-- property image -->

        <p>Caution: You must sell all houses of the full set to sell your property.</p>

        <div class="flex gap-4">
          <button phx-click="downgrade_property" class="btn btn-primary">
            Sell Property
          </button>
          <button phx-click="cancel_buying" class="btn btn-secondary">
            Cancel
          </button>
        </div>
      </div>
    </.modal>
    """
  end
end
