defmodule MonopolyWeb.Components.PlayerDashboardTest do
  use MonopolyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias MonopolyWeb.Components.PlayerDashboard

  describe "player_dashboard component" do
    test "renders player's name and money" do
      player = %{
        id: "player-1",
        name: "Test Player",
        color: "#FF0000",
        money: 1500,
        total_worth: 2000,
        properties: [],
        in_jail: false,
        get_out_of_jail_cards: 0,
        has_rolled: false
      }

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1"
      })

      assert html =~ player.name
      assert html =~ "$1500"
      assert html =~ "$2000"
      assert html =~ "Roll Dice"
      assert html =~ "End Turn"
    end

    test "shows jail status when player is in jail" do
      player = %{
        id: "player-1",
        name: "Test Player",
        color: "#FF0000",
        money: 1500,
        total_worth: 2000,
        properties: [],
        in_jail: true,
        get_out_of_jail_cards: 0,
        has_rolled: false
      }

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1"
      })

      assert html =~ "In Jail"
    end

    test "displays properties correctly" do
      properties = [
        %{
          name: "Boardwalk",
          group: "dark_blue",
          houses: 0,
          hotel: false,
          mortgaged: false
        },
        %{
          name: "Park Place",
          group: "dark_blue",
          houses: 3,
          hotel: false,
          mortgaged: false
        },
        %{
          name: "Mediterranean Avenue",
          group: "brown",
          houses: 0,
          hotel: true,
          mortgaged: false
        },
        %{
          name: "Baltic Avenue",
          group: "brown",
          houses: 0,
          hotel: false,
          mortgaged: true
        }
      ]

      player = %{
        id: "player-1",
        name: "Test Player",
        color: "#FF0000",
        money: 1500,
        total_worth: 2000,
        properties: properties,
        in_jail: false,
        get_out_of_jail_cards: 2,
        has_rolled: false
      }

      html = render_component(&PlayerDashboard.player_dashboard/1, %{
        player: player,
        current_player_id: "player-1"
      })

      assert html =~ "Properties (4)"
      assert html =~ "B</div>" # First letter of Boardwalk
      assert html =~ "3</span>" # 3 houses
      assert html =~ "<span class=\"hotel\">H</span>" # Hotel
      assert html =~ "<div class=\"mortgaged-indicator\">M</div>" # Mortgaged indicator
      assert html =~ "Get Out of Jail Free"
      assert html =~ "2</div>" # Count of Get Out of Jail Free cards
    end
  end
end
