defmodule MonopolyWeb.Components.PlayerDashboard do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import MonopolyWeb.CoreComponents
  import MonopolyWeb.Helpers.SpriteHelper

  # Main player dashboard component
  attr :player, :map, required: true, doc: "The player data to display"
  attr :current_player_id, :string, default: nil, doc: "ID of the current active player"
  attr :on_roll_dice, JS, default: %JS{}, doc: "JS command for roll dice action"
  attr :on_end_turn, JS, default: %JS{}, doc: "JS command for end turn action"
  attr :properties, :list, default: [], doc: "List of properties owned by player"
  attr :dice_result, :integer, default: nil, doc: "Result of the dice roll"
  attr :dice_values, :any, default: nil, doc: "Individual dice values as a tuple"
  attr :is_doubles, :boolean, default: false, doc: "Whether the roll was doubles"
  attr :doubles_notification, :string, default: nil, doc: "Notification for doubles"
  attr :doubles_count, :integer, default: 0, doc: "Count of consecutive doubles"
  attr :jail_notification, :string, default: nil, doc: "Notification for jail"
  attr :roll, :boolean, default: false, doc: "Whether player can roll dice"
  attr :end_turn, :boolean, default: false, doc: "Whether player can end their turn"

  def player_dashboard(assigns) do
    # Get player color based on sprite_id
    assigns = assign(assigns, :color, get_player_color(assigns.player.sprite_id))

    ~H"""
    <div id="player-dashboard" class="player-dashboard">
      <div class="dashboard-header">
        <div class="player-name" style={"color: #{@color};"}>
          <img
            src={"/images/sprites/" <> get_sprite_filename(@player.sprite_id)}
            alt="Player Sprite"
            class="h-15 w-15 inline-block"
          />
          <%= @player.name %>
        </div>

        <!-- Status indicators container with fixed height -->
        <div class="status-indicators">
          <!-- Current turn indicator on its own row -->
          <div :if={@player.id == @current_player_id} class="turn-indicator mb-1 flex items-center justify-end">
            <span>Current Turn</span>
            <.icon name="hero-play" class="h-4 w-4 ml-1" />
          </div>

          <!-- Jail status on its own row -->
          <div :if={@player.in_jail} class="jail-status flex items-center justify-end">
            <span>In Jail (<%= @player.jail_turns %> turns)</span>
            <.icon name="hero-lock-closed" class="h-4 w-4 ml-1" />
          </div>
        </div>
      </div>

      <div class="dashboard-body">
        <.money_display money={@player.money} />
        <.total_worth money={@player.money} properties={@properties} />

        <div class="dashboard-actions">
          <button
            phx-click={@on_roll_dice}
            disabled={not @roll}
            class="roll-dice-btn">
            <.icon name="hero-cube" class="h-4 w-4" />
            Roll Dice
          </button>

          <button
            phx-click={@on_end_turn}
            disabled={not @end_turn}
            class="end-turn-btn">
            <.icon name="hero-arrow-right" class="h-4 w-4" />
            End Turn
          </button>
        </div>

        <.property_display properties={@properties} />
        <.card_collection cards={@player.cards} />

        <!-- Dice results and notifications in dashboard -->
        <%= if assigns[:dice_result] != nil do %>
          <div class="dice-results-dashboard mt-4 p-3 bg-gray-100 rounded text-center">
            <h3 class="text-sm font-semibold mb-1">Dice Roll</h3>
            <div class="flex justify-center items-center gap-2">
              <%= if is_tuple(assigns[:dice_values]) do %>
                <div class="dice bg-white w-8 h-8 rounded shadow flex items-center justify-center font-bold">
                  <%= elem(assigns.dice_values, 0) %>
                </div>
                <div class="dice bg-white w-8 h-8 rounded shadow flex items-center justify-center font-bold">
                  <%= elem(assigns.dice_values, 1) %>
                </div>
                <div class="dice-sum ml-2">
                  = <span class="font-bold"><%= assigns.dice_result %></span>
                  <%= if assigns[:is_doubles] && assigns.is_doubles do %>
                    <span class="text-xs ml-1 text-green-600 font-semibold">Doubles!</span>
                  <% end %>
                </div>
              <% else %>
                <div class="font-bold"><%= assigns.dice_result %></div>
              <% end %>
            </div>

            <!-- Jail notification (in red) -->
            <%= if assigns[:jail_notification] do %>
              <div class="jail-notification mt-2 text-red-600 font-semibold p-1 bg-red-50 rounded">
                <%= @jail_notification %>
              </div>
            <% end %>

            <!-- Doubles notification (in green) -->
            <%= if assigns[:doubles_notification] do %>
              <div class="doubles-notification mt-2 text-green-600 font-semibold">
                <%= @doubles_notification %>
              </div>
            <% end %>

            <!-- Doubles counter -->
            <%= if assigns[:doubles_count] && @doubles_count > 0 && @doubles_count < 3 do %>
              <div class="doubles-counter mt-1 text-sm">
                <span>Consecutive doubles: <%= @doubles_count %>/3</span>
              </div>
            <% end %>
          </div>
        <% end %>
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

  # Total worth component - now calculates based on money and property values
  attr :money, :integer, required: true, doc: "Player's current money amount"
  attr :properties, :list, required: true, doc: "List of properties owned by player"

  def total_worth(assigns) do
    # Calculate total worth as money + value of properties
    property_value = Enum.reduce(assigns.properties, 0, fn p, acc ->
      acc + (p.buy_cost || 0) + calculate_upgrades_value(p)
    end)

    total = assigns.money + property_value
    assigns = assign(assigns, :total, total)

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
                title={"#{property.name}#{if property_mortgaged?(property), do: " (Mortgaged)", else: ""}"}
              >
                <div class="property-initial"><%= String.first(property.name) %></div>
                <%= if property.upgrades && property.upgrades > 1 && !Enum.member?(["railroad", "utility"], property.type) do %>
                  <div class="property-buildings">
                    <%= if property.upgrades == 6 do %>
                      <span class="hotel">H</span>
                    <% else %>
                      <span class="houses"><%= property.upgrades - 1 %></span>
                    <% end %>
                  </div>
                <% end %>
                <%= if property_mortgaged?(property) do %>
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

  # Helper function to determine property color based on type
  defp property_color(property) do
    case property.type do
      "brown" -> "#93572D"
      "light blue" -> "#70ECF2"
      "pink" -> "#FF66F2"
      "orange" -> "#FE9B4F"
      "red" -> "#FE5E51"
      "yellow" -> "#FEDB62"
      "green" -> "#4EC858"
      "blue" -> "#5175E9"
      "railroad" -> "#000000"
      "utility" -> "#28A745"
      _ -> "#CCCCCC"
    end
  end

  # Get out of jail free card collection - updated to use cards from backend
  attr :cards, :list, default: [], doc: "Player's cards"

  def card_collection(assigns) do
    jail_free_cards = Enum.count(assigns.cards || [], fn card ->
      card.effect == {:get_out_of_jail, true}
    end)

    assigns = assign(assigns, :get_out_of_jail_cards, jail_free_cards)

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

  # Helper functions to determine player color based on sprite_id
  defp get_player_color(sprite_id) when is_integer(sprite_id) do
    case rem(sprite_id, 6) do
      0 -> "#FF0000" # Red
      1 -> "#00FF00" # Green
      2 -> "#0000FF" # Blue
      3 -> "#FFFF00" # Yellow
      4 -> "#FF00FF" # Magenta
      5 -> "#00FFFF" # Cyan
      _ -> "#FFFFFF" # White (fallback)
    end
  end
  defp get_player_color(_), do: "#FF0000" # Default to red

  # Helper functions for property attributes
  defp property_mortgaged?(property), do: Map.get(property, :mortgaged, false)

  # Calculate the value of upgrades (houses/hotels) for total worth
  defp calculate_upgrades_value(property) do
    upgrades = property.upgrades || 0
    house_price = property.house_price || 0
    hotel_price = property.hotel_price || 0

    cond do
      upgrades >= 6 -> 4 * house_price + hotel_price # Hotel (4 houses + 1 hotel)
      upgrades > 1 -> (upgrades - 1) * house_price   # Houses
      true -> 0                                      # No upgrades
    end
  end
end
