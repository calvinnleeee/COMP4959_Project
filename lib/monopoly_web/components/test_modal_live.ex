defmodule MonopolyWeb.TestModalLive do
  use MonopolyWeb, :live_view
  import MonopolyWeb.CoreComponents
  alias MonopolyWeb.Components.PropertyActionModal

  def mount(_params, _session, socket) do
    test_property = %{
      name: "Boardwalk",
      buy_cost: 400,
      upgrades: 2
    }

    {:ok,
     assign(socket,
       show_property_modal: true,
       property: test_property,
       buy_prop: true,
       upgrade_prop: true,
       sell_prop: true
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <PropertyActionModal.property_action_modal
        id="test-property-modal"
        show={@show_property_modal}
        property={@property}
        buy_prop={@buy_prop}
        upgrade_prop={@upgrade_prop}
        sell_prop={@sell_prop}
        on_cancel={hide_modal("test-property-modal")}
      />

      <button phx-click="toggle_buy">Toggle Buy</button>

    </div>
    """
  end

  def handle_event("toggle_buy", _params, socket) do
  {:noreply, update(socket, :buy_prop, fn val -> !val end)}
end

end
