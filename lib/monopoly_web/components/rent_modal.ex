defmodule MonopolyWeb.Components.RentModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents
  alias GameObjects.Property

  @doc """
  Renders a Card Modal for alerting the player that they are paying rent.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :property, :map, required: true, doc: "Property that was landed on"
  attr :dice_result, :integer, required: true, doc: "Die result for the turn"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def rent_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="card-modal-content p-6">
        <h3 class="text-lg font-bold mb-4">You landed on {@property.owner.name}'s {@property.name}!</h3>
        <p class="mb-6">You need to pay ${Property.charge_rent(@property, @dice_result)} to {@property.owner.name}.</p>
      </div>
    </.modal>
    """
  end
end
