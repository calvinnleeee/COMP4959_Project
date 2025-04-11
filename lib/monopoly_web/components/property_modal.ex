defmodule MonopolyWeb.Components.PropertyModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents
  alias Phoenix.LiveView.JS

  @doc """
  Renders a Property Modal for confirming property actions.
  """
  attr :id, :string, required: true
  attr :player, :map, required: true, doc: "Current player's information"
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property info to display"
  attr :on_cancel, JS, default: %JS{}, doc: "JS command for cancel action"

  def property_modal(assigns) do
    player = assigns.player
    property = assigns.property
    can_buy =
      property.owner == nil && property.buy_cost != nil && property.buy_cost <= player.money
    can_upgrade =
      property.owner != nil &&
      property.owner == player.id &&
      property.house_price != nil &&
      cond do
        0 < property.upgrades &&
            property.upgrades < length(property.rent_cost) - 2 ->
          property.house_price < player.money

        property.upgrades == length(property.rent_cost) - 2 ->
          property.hotel_price < player.money

        true ->
          false
      end
    can_sell = property.owner != nil && property.owner == player.id
    assigns =
      assign(assigns, can_buy: can_buy, can_upgrade: can_upgrade, can_sell: can_sell)

    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="buy-modal-content p-6 z-10">
        <h2 class="text-xl font-bold mb-4">{@property.name}</h2>
        <p class="mb-6">
          <%= @property.name %> : <span class="font-semibold">$<%= @property.buy_cost %></span>
        </p>

        <div class="flex justify-start gap-4">
          <button
            phx-click="buy_prop"
            class={"px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 #{if !@can_buy, do: " hidden"}"}
          >
            Buy
          </button>
          <button
            phx-click="upgrade_prop"
            class={"px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 #{if !@can_upgrade, do: " hidden"}"}
          >
            Upgrade
          </button>
          <button
            phx-click="sell_prop"
            class={"px-4 py-2 bg-orange-500 text-white rounded hover:bg-green-600 #{if !@can_sell, do: " hidden"}"}
          >
            Sell
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
