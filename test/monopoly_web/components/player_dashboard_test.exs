defmodule MonopolyWeb.Components.PlayerDashboardTest do
  use MonopolyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias MonopolyWeb.Components.PlayerDashboard

  describe "player_dashboard component" do
    test "renders player's name and money" do
      # Create a test player with the new backend structure
      player = %{
        id: "player-1",
        name: "Test Player",
        sprite_id: 0,  # Will be converted to color
        money: 1500,
        position: 0,
        cards: [],
        in_jail: false,
        jail_turns: 0,
        has_rolled: false
      }

      # Test properties matching backend structure
      properties = []

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1",
        properties: properties
      })

      assert html =~ player.name
      assert html =~ "$1500"
      assert html =~ "Roll Dice"
      assert html =~ "End Turn"
    end

    test "shows jail status when player is in jail" do
      player = %{
        id: "player-1",
        name: "Test Player",
        sprite_id: 1,
        money: 1500,
        position: 10, # Jail position
        cards: [],
        in_jail: true,
        jail_turns: 2,
        has_rolled: false
      }

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1",
        properties: []
      })

      assert html =~ "In Jail"
      assert html =~ "(2 turns)"
    end

    test "displays properties correctly" do
      # Create properties that match the backend structure
      properties = [
        %{
          id: 1,
          name: "Boardwalk",
          type: "dark_blue",
          buy_cost: 400,
          rent_cost: [50, 200, 600, 1400, 1700, 2000],
          upgrades: 0,
          house_price: 200,
          hotel_price: 200,
          owner: "player-1"
        },
        %{
          id: 2,
          name: "Park Place",
          type: "dark_blue",
          buy_cost: 350,
          rent_cost: [35, 175, 500, 1100, 1300, 1500],
          upgrades: 3, # 2 houses (upgrades - 1)
          house_price: 200,
          hotel_price: 200,
          owner: "player-1"
        },
        %{
          id: 3,
          name: "Mediterranean Avenue",
          type: "brown",
          buy_cost: 60,
          rent_cost: [2, 10, 30, 90, 160, 250],
          upgrades: 6, # Hotel
          house_price: 50,
          hotel_price: 50,
          owner: "player-1"
        },
        %{
          id: 4,
          name: "Baltic Avenue",
          type: "brown",
          buy_cost: 60,
          rent_cost: [4, 20, 60, 180, 320, 450],
          upgrades: 0,
          house_price: 50,
          hotel_price: 50,
          mortgaged: true, # Add mortgaged property
          owner: "player-1"
        }
      ]

      player = %{
        id: "player-1",
        name: "Test Player",
        sprite_id: 0,
        money: 1500,
        position: 0,
        cards: [
          %{
            id: "get-out-of-jail-1",
            name: "Get Out of Jail Free",
            type: "chance",
            effect: {:get_out_of_jail, true},
            owned: true
          },
          %{
            id: "get-out-of-jail-2",
            name: "Get Out of Jail Free",
            type: "community_chest",
            effect: {:get_out_of_jail, true},
            owned: true
          }
        ],
        in_jail: false,
        jail_turns: 0,
        has_rolled: false
      }

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1",
        properties: properties
      })

      assert html =~ "Properties (4)"
      assert html =~ "B</div>" # First letter of Boardwalk
      assert html =~ "2</span>" # 2 houses (upgrades 3 - 1)
      assert html =~ "<span class=\"hotel\">H</span>" # Hotel
      assert html =~ "<div class=\"mortgaged-indicator\">M</div>" # Mortgaged indicator
      assert html =~ "Get Out of Jail Free"
      assert html =~ "2</div>" # Count of Get Out of Jail Free cards
    end
  end
end
