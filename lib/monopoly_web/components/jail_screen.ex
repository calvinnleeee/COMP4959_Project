defmodule MyAppWeb.JailLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Initialize with 3 turns remaining, no dice roll result
    {:ok, assign(socket, turns_remaining: 3, dice: nil, result: nil)}
  end

  def render(assigns) do
    ~L"""
    <div class="max-w-lg mx-auto my-12 p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>
      <p class="text-lg mb-4">Turns remaining in jail: <%= @turns_remaining %></p>

      <div class="flex justify-center space-x-4 mb-6">
        <button phx-click="pay" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Pay $50
        </button>
        <button phx-click="card" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
          Use Get Out of Jail Free Card
        </button>
        <button phx-click="roll" class="bg-yellow-500 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded">
          Roll Doubles
        </button>
      </div>

      <div class="mt-4 text-xl">
        <%= if @dice do %>
          <p>You rolled: <%= Enum.join(@dice, ", ") %></p>
          <p class="font-bold mt-2"><%= @result %></p>
        <% end %>
      </div>
    </div>
    """
  end

  # Handle the "Pay $50" event
  def handle_event("pay", _params, socket) do
    {:noreply, assign(socket, turns_remaining: 0, result: "You paid $50 and are now free!")}
  end

  # Handle the "Use Get Out of Jail Free Card" event
  def handle_event("card", _params, socket) do
    {:noreply, assign(socket, turns_remaining: 0, result: "You used a Get Out of Jail Free card and are now free!")}
  end

  # Handle the "Roll Doubles" event
  def handle_event("roll", _params, socket) do
    dice = [roll_die(), roll_die()]
    is_doubles = Enum.uniq(dice) |> length() == 1

    result =
      if is_doubles do
        "Doubles! You're free from jail!"
      else
        "Not doubles. Try again next turn."
      end

    new_turns = if is_doubles, do: 0, else: max(socket.assigns.turns_remaining - 1, 0)
    {:noreply, assign(socket, dice: dice, result: result, turns_remaining: new_turns)}
  end

  defp roll_die do
    :rand.uniform(6)
  end
end
