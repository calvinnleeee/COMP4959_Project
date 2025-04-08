defmodule MonopolyWeb.Components.PropertyModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
    Renders a modal for buying/upgrading/downgrading property based on props
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :show, :boolean, default: false
  attr :property, :map, required: true
  attr :buy_prop, :boolean, default: false
  attr :upgrade_prop, :boolean, default: false
  attr :sell_prop, :boolean, default: false
  attr :on_cancel, :any, default: nil

  def property_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class={"modal buy " <> @class}>
        <h2 class="text-xl font-bold mb-4">{@property.name}</h2>

        <p class="mb-6">
          Cost: <span class="font-semibold">${@property.buy_cost}</span>
          Type: <span class="font-semibold"><%= @property.type %></span>
        </p>

        <div class="flex gap-4">
            <button
              phx-click="buy_prop"
              class={"btn btn-primary #{if !@buy_prop, do: " opacity-50 cursor-not-allowed"}"}
              disabled={!@buy_prop}>
              Buy Property
            </button>

            <button
              phx-click="upgrade_prop"
              class={"btn btn-primary #{if !@upgrade_prop, do: " opacity-50 cursor-not-allowed"}"}
              disabled={!@upgrade_prop}>
              Buy House
            </button>

            <button
              phx-click="sell_prop"
              class={"btn btn-primary #{if !@sell_prop, do: " opacity-50 cursor-not-allowed"}"}
              disabled={!@sell_prop}>
              Sell Property
            </button>

          <button phx-click="cancel_buying" class="btn btn-secondary">Leave</button>
        </div>
      </div>
    </.modal>
    """
  end
end
