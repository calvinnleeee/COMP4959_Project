defmodule MonopolyWeb.Components.PropertyActionModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders a modal for buying/upgrading/downgrading property based on props

  TODO buy property modal is shown underneath the dashboard (z-index needs to be updated)
  TODO when buy modal pops up, i can press leave to not buy it, end turn,
  then the turn counter doesn't increment (next player never gets their turn ???)
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :show, :boolean, default: false
  attr :property, :map, required: true
  attr :can_buy, :boolean, default: false
  attr :can_upgrade, :boolean, default: false
  attr :can_downgrade, :boolean, default: false
  attr :on_cancel, :any, default: nil

  def property_action_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class={"modal buy " <> @class}>
        <h2 class="text-xl font-bold mb-4"><%= @property.name %></h2>

        <p class="mb-6">
          Cost: <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>

        <div class="flex gap-4">
          <%= if @can_buy do %>
            <button phx-click="buy_prop" class="btn btn-primary">Buy</button>
          <% end %>

          <%= if @can_upgrade do %>
            <button phx-click="upgrade_property" class="btn btn-primary">Upgrade</button>
          <% end %>

          <%= if @can_downgrade do %>
            <button phx-click="downgrade_property" class="btn btn-primary">Sell</button>
          <% end %>

          <button phx-click="cancel_buying" class="btn btn-secondary">Cancel</button>
        </div>
      </div>
    </.modal>
    """
  end
end
