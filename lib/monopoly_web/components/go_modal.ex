defmodule MonopolyWeb.Components.GoModal do
  use Phoenix.Component
  import MonopolyWeb.CoreComponents

  @doc """
  Renders a Modal for indicating the player passed Go.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil, doc: "JS command for cancel action"

  def go_modal(assigns) do
    ~H"""
    <.modal id={@id} show={@show} on_cancel={@on_cancel || hide_modal(@id)}>
      <div class="card-modal-content p-6 z-10">
        <h3 class="text-lg font-bold mb-4">You passed Go!</h3>

        <p class="mb-6">You gained $200.</p>

      </div>
    </.modal>
    """
  end
end
