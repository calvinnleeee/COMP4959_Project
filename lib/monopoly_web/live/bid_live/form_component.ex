defmodule MonopolyWeb.BidLive.FormComponent do
  use MonopolyWeb, :live_component

  alias Monopoly.AuctionLive

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage bid records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="bid-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:player]} type="text" label="Player" />
        <.input field={@form[:bid_price]} type="number" label="Bid price" />
        <.input field={@form[:property_prices]} type="text" label="Property prices" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Bid</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bid: bid} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(AuctionLive.change_bid(bid))
     end)}
  end

  @impl true
  def handle_event("validate", %{"bid" => bid_params}, socket) do
    changeset = AuctionLive.change_bid(socket.assigns.bid, bid_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bid" => bid_params}, socket) do
    save_bid(socket, socket.assigns.action, bid_params)
  end

  defp save_bid(socket, :edit, bid_params) do
    case AuctionLive.update_bid(socket.assigns.bid, bid_params) do
      {:ok, bid} ->
        notify_parent({:saved, bid})

        {:noreply,
         socket
         |> put_flash(:info, "Bid updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bid(socket, :new, bid_params) do
    case AuctionLive.create_bid(bid_params) do
      {:ok, bid} ->
        notify_parent({:saved, bid})

        {:noreply,
         socket
         |> put_flash(:info, "Bid created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
