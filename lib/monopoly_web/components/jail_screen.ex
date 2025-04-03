defmodule MonopolyWeb.JailLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Initialize with 3 turns remaining, no dice roll result
    {:ok, assign(socket, turns_remaining: 3, dice: nil, result: nil)}
  end

  def render(assigns) do
    ~L"""
    <style>
    .jail-container {
      max-width: 512px;
      margin: 48px auto;
      padding: 24px;
      background-color: #f7fafc; /* light gray */
      border: 1px solid #e2e8f0; /* light gray border */
      border-radius: 8px;
      text-align: center;
    }

    .jail-header {
      font-size: 1.5rem;
      font-weight: bold;
      color: #2d3748; /* dark gray */
      margin-bottom: 16px;
    }

    .jail-description {
      font-size: 1.125rem;
      margin-bottom: 16px;
    }

    .button-group {
      display: flex;
      justify-content: center;
      gap: 16px;
      margin-bottom: 24px;
    }

    .jail-button {
      padding: 8px 16px;
      font-weight: bold;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    /* Pay button styles */
    .pay-button {
      background-color: #4299e1;
    }

    .pay-button:hover {
      background-color: #2b6cb0;
    }

    /* Card button styles */
    .card-button {
      background-color: #48bb78;
    }

    .card-button:hover {
      background-color: #2f855a;
    }

    /* Roll button styles */
    .roll-button {
      background-color: #ecc94b;
    }

    .roll-button:hover {
      background-color: #d69e2e;
    }

    .result-text {
      margin-top: 16px;
      font-size: 1.25rem;
    }

    .result-text p {
      margin: 8px 0;
    }

    .result-text .bold {
      font-weight: bold;
      margin-top: 8px;
    }

    </style>
    <div class="jail-container">
      <h1 class="jail-header">Jail Screen</h1>

      <div class="jail-image">
        <img src="/images/jail_scene.png" alt="Jail scene" class="jail-scene-img" />
      </div>
      <p class="jail-description">Turns remaining in jail: <%= @turns_remaining %></p>

      <div class="button-group">
        <button phx-click="pay" class="jail-button pay-button">
          Pay $50
        </button>
        <button phx-click="card" class="jail-button card-button">
          Use Get Out of Jail Free Card
        </button>
        <button phx-click="roll" class="jail-button roll-button">
          Roll Doubles
        </button>
      </div>

      <div class="result-text">
        <%= if @dice do %>
          <p>You rolled: <%= Enum.join(@dice, ", ") %></p>
          <p class="bold"><%= @result %></p>
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
