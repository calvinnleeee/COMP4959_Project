defmodule MonopolyWeb.Components.PlayerDashboard do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import MonopolyWeb.CoreComponents

  # Main player dashboard component
  attr :player, :map, required: true, doc: "The player data to display"
  attr :current_player_id, :string, default: nil, doc: "ID of the current active player"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :on_end_turn, JS, default: %JS{}, doc: "JS command for end turn action"

  def player_dashboard(assigns) do
    ~H"""
    <div id="player-dashboard" class="player-dashboard">
      <div class="dashboard-header">
        <div class="player-name" style={"color: #{@player.color};"}>
          <%= @player.name %>
          <span :if={@player.id == @current_player_id} class="turn-indicator">
            <.icon name="hero-play" class="h-4 w-4" />
            Current Turn
          </span>
        </div>

        <div class="dashboard-status">
          <span :if={@player.in_jail} class="jail-status">
            <.icon name="hero-lock-closed" class="h-4 w-4" />
            In Jail
          </span>
        </div>
      </div>

      <div class="dashboard-body">
        <.money_display money={@player.money} />
        <.total_worth total={@player.total_worth} />

        <div class="dashboard-actions">
          <button
            phx-click={@on_roll_dice}
            disabled={@player.id != @current_player_id || @player.has_rolled}
            class="roll-dice-btn">
            <.icon name="hero-cube" class="h-4 w-4" />
            Roll Dice
          </button>

          <button
            phx-click={@on_end_turn}
            disabled={@player.id != @current_player_id || !@player.has_rolled}
            class="end-turn-btn">
            <.icon name="hero-arrow-right" class="h-4 w-4" />
            End Turn
          </button>
        </div>

        <.property_display properties={@player.properties} />
        <.card_collection get_out_of_jail_cards={@player.get_out_of_jail_cards} />
      </div>
    </div>
    """
  end

  # Money display component
  attr :money, :integer, required: true, doc: "Player's current money amount"

  def money_display(assigns) do
    ~H"""
    <div class="money-display">
      <h3>Cash</h3>
      <div class="money-amount">$<%= @money %></div>
    </div>
    """
  end

  # Total worth component
  attr :total, :integer, required: true, doc: "Player's total worth"

  def total_worth(assigns) do
    ~H"""
    <div class="total-worth">
      <h3>Total Worth</h3>
      <div class="worth-amount">$<%= @total %></div>
    </div>
    """
  end

  # Property display component
  attr :properties, :list, required: true, doc: "List of properties owned by player"

  def property_display(assigns) do
    ~H"""
    <div class="property-display">
      <h3>Properties (<%= length(@properties) %>)</h3>
      <div class="property-list">
        <%= if Enum.empty?(@properties) do %>
          <div class="no-properties">No properties owned</div>
        <% else %>
          <div class="property-grid">
            <%= for property <- @properties do %>
              <div
                class="property-tile"
                style={"background-color: #{property_color(property)}"}
                title={"#{property.name}#{if property.mortgaged, do: " (Mortgaged)", else: ""}"}
              >
                <div class="property-initial"><%= String.first(property.name) %></div>
                <%= if property.houses > 0 || property.hotel do %>
                  <div class="property-buildings">
                    <%= if property.hotel do %>
                      <span class="hotel">H</span>
                    <% else %>
                      <span class="houses"><%= property.houses %></span>
                    <% end %>
                  </div>
                <% end %>
                <%= if property.mortgaged do %>
                  <div class="mortgaged-indicator">M</div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper function to determine property color
  defp property_color(property) do
    case property.group do
      "brown" -> "#955436"
      "light_blue" -> "#AAE0FA"
      "pink" -> "#D93A96"
      "orange" -> "#F7941D"
      "red" -> "#ED1B24"
      "yellow" -> "#FEF200"
      "green" -> "#1FB25A"
      "dark_blue" -> "#0072BB"
      "railroad" -> "#000000"
      "utility" -> "#28A745"
      _ -> "#CCCCCC"
    end
  end

  # Get out of jail free card collection
  attr :get_out_of_jail_cards, :integer, default: 0, doc: "Number of Get Out of Jail Free cards"

  def card_collection(assigns) do
    ~H"""
    <div class="card-collection">
      <h3>Special Cards</h3>
      <div class="cards-list">
        <div class="jail-free-card" title="Get Out of Jail Free">
          <div class="card-count"><%= @get_out_of_jail_cards %></div>
          <div class="card-name">Get Out of Jail Free</div>
        </div>
      </div>
    </div>
    """
  end
end
