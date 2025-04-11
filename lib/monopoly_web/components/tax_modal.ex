defmodule MonopolyWeb.Components.TaxModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders a Card Modal for handling parking and tax tiles.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :tile, :map, required: true, doc: "The tax or parking tile landed on"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def tax_modal(assigns) do
    cost = cond do
      assigns.tile.type == "tax" ->
        if String.contains?(assigns.tile.name, "Income") do
          200
        else
          75
        end
      assigns.tile.type == "parking" ->
        Enum.at(assigns.tile.rent_cost, 0)
      true -> 0
    end
    assigns = assign(assigns, cost: cost)

    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="card-modal-content p-6">
        <h3 class="text-lg font-bold mb-4">You landed on {@tile.name}! :(</h3>
        <p class="mb-6">You pay ${@cost} to the banker.</p>
      </div>
    </.modal>
    """
  end
end
