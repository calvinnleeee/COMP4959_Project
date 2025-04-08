defmodule MonopolyWeb.Components.UpgradeProperty do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders an Upgrade Property Modal to build up to five houses on the property the player owned.
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_buy, :any, default: nil, doc: "JS command or event for buying"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def upgrade_prop_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <%!-- comment out for design adjustment: <div class="buy-modal-content p-6"> --%>
      <div class={"modal buy " <> @class}>
        <h2 class="text-xl font-bold mb-4">Upgrade Property</h2>
        <p class="mb-6">
          <%!-- What & How many to build --%>
          <%= @property.name %>

          <%!-- upgrades: an integer from 0-7 that represents the number of houses or hotels on the property. 0 is no houses, 1 is full set, 2,3,4,5 is house, 6 is a hotel. --%>

          <span class="font-semibold">$<%= @property.buy_cost %></span>

        </p>
        <!-- property image -->
        <div class="flex gap-4">
          <button phx-click="upgrade_property" class="btn btn-primary">
            Build House
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
