defmodule MonopolyWeb.Components.CardModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders a Card Modal for when players gain a card.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :card, :map, required: true, doc: "Card info to display"
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def card_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="card-modal-content p-6">
        <h3 class="text-lg font-bold mb-4">You got a {@card.type} card!</h3>
        <h2 class="text-xl font-bold mb-4">{@card.name}</h2>
        <%= if elem(@card.effect, 0) != :get_out_of_jail do %>
          <p class="mb-6">You {elem(@card.effect, 0)} ${elem(@card.effect, 1)}.</p>
        <% else %>
          <p class="mb-6">You gained a Get Out of Jail Free card.</p>
        <% end %>

      </div>
    </.modal>
    """
  end
end
