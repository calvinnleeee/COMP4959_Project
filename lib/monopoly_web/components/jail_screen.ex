<<<<<<< HEAD
defmodule MonopolyWeb.Components.JailScreen do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
=======
defmodule MonopolyWeb.JailLive do
  use Phoenix.LiveView
>>>>>>> ccaba33 (edit styling to use native CSS)

  attr :player, :map, required: true, doc: "The player data to display"
  attr :current_player_id, :string, default: nil, doc: "ID of the current active player"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :dice, :list, default: nil, doc: "List of dice values rolled"
  attr :result, :string, default: nil, doc: "Result message after rolling dice"

<<<<<<< HEAD
  def jail_screen(assigns) do
    ~H"""
    <div id="jail-screen" class="jail-screen max-w-lg my-12 mx-auto p-6 bg-gray-100 border border-gray-300 rounded-lg text-center">
      <h1 class="text-2xl font-bold text-gray-800 mb-4">Jail Screen</h1>

      <div class="jail-image">
        <img src="/images/jail_scene.png" alt="Jail scene" class="mx-auto" />
      </div>
      <p class="text-lg mb-4">Turns remaining in jail: <%= @player.jail_turns %></p>

      <div class="flex justify-center gap-4 mb-6">
        <button
          phx-click={@on_roll_dice}
          class="px-4 py-2 font-bold text-white rounded cursor-pointer bg-yellow-500 hover:bg-yellow-600">
          Roll Dice
        </button>
      </div>
      <div class="mt-4 text-xl">
        <%= if @dice do %>
          <p class="my-2">You rolled: <%= elem(assigns.dice, 0) %> and <%= elem(assigns.dice, 1) %></p>
          <p class="font-bold mt-2">
            <%= @result %>
          </p>
=======
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
>>>>>>> ccaba33 (edit styling to use native CSS)
        <% end %>
      </div>
    </div>
    """
  end
end
