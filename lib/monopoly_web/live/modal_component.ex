defmodule MonopolyWeb.ModalComponent do
  use MonopolyWeb, :live_component

  # modal (popup) component for buy & auction
  # @inner_content : receive from LiveView; property buy || auction

  def render(assigns) do
    ~H"""
    <div id="modal" class="modal-overlay">
        <div class="modal-content">
          <%= @inner_content %>
        </div>
    </div>
    """
  end
end
