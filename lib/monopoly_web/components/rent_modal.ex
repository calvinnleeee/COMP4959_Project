defmodule MonopolyWeb.Components.RentModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents
  alias GameObjects.Property

  @doc """
  Renders a Card Modal for alerting the player that they are paying rent.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :players, :list, required: true, doc: "List of players in the game"
  attr :property, :map, required: true, doc: "Property that was landed on"
  attr :dice_result, :integer, required: true, doc: "Die result for the turn"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def rent_modal(assigns) do
    owner_name =
      if assigns.property.owner == nil do
        ""
      else
        players = assigns.players
        owner_id = assigns.property.owner

        case Enum.find(players, fn player -> player.id == owner_id end) do
          nil -> ""
          player -> player.name
        end
      end

    rent =
      if assigns.property.type in [
        "brown",
        "light blue",
        "utility", "railroad",
        "pink",
        "orange",
        "red",
        "yellow",
        "green",
        "blue"
      ] do
      Property.charge_rent(assigns.property, assigns.dice_result)
      else
        0
      end
    assigns = assign(assigns, owner_name: owner_name, rent: rent)

    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="card-modal-content p-6">
        <h3 class="text-lg font-bold mb-4">You landed on {@owner_name}'s {@property.name}!</h3>
        <p class="mb-6">You need to pay ${@rent} to {@owner_name}.</p>
      </div>
    </.modal>
    """
  end
end
