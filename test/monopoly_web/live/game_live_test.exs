defmodule MonopolyWeb.GameLiveTest do
  use MonopolyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "player dashboard" do
    test "displays player dashboard for current player", %{conn: conn} do
      # Mock your game state here to include a player
      game = %{
        id: "game-1",
        current_player_id: "player-1",
        players: [
          %{
            id: "player-1",
            name: "Player 1",
            color: "#FF0000",
            money: 1500,
            total_worth: 1500,
            properties: [],
            in_jail: false,
            get_out_of_jail_cards: 0,
            has_rolled: false
          }
        ]
      }

      # You'll need to modify this to match how your app initializes the game
      {:ok, view, _html} = live(conn, ~p"/game/#{game.id}")

      # Set the game state in the socket assigns
      view |> element("#player-dashboard") |> render()

      # Assert that the dashboard contains expected elements
      assert has_element?(view, "#player-dashboard")
      assert has_element?(view, ".player-name", "Player 1")
      assert has_element?(view, ".money-amount", "$1500")
      assert has_element?(view, ".roll-dice-btn")
    end

    test "enables/disables buttons based on turn status", %{conn: conn} do
      # Set up a game where player has already rolled
      game = %{
        id: "game-1",
        current_player_id: "player-1",
        players: [
          %{
            id: "player-1",
            name: "Player 1",
            color: "#FF0000",
            money: 1500,
            total_worth: 1500,
            properties: [],
            in_jail: false,
            get_out_of_jail_cards: 0,
            has_rolled: true
          }
        ]
      }

      # You'll need to modify this to match how your app initializes the game
      {:ok, view, _html} = live(conn, ~p"/game/#{game.id}")

      # The roll dice button should be disabled when player has already rolled
      assert view
             |> element(".roll-dice-btn")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.attribute("disabled") == [""]

      # The end turn button should be enabled
      assert view
             |> element(".end-turn-btn")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.attribute("disabled") == []
    end

    test "clicking roll dice button triggers event", %{conn: conn} do
      game = %{
        id: "game-1",
        current_player_id: "player-1",
        players: [
          %{
            id: "player-1",
            name: "Player 1",
            color: "#FF0000",
            money: 1500,
            total_worth: 1500,
            properties: [],
            in_jail: false,
            get_out_of_jail_cards: 0,
            has_rolled: false
          }
        ]
      }

      # Setup the mock game
      {:ok, view, _html} = live(conn, ~p"/game/#{game.id}")

      # Click the roll dice button
      view |> element(".roll-dice-btn") |> render_click()

      # Now verify that the event handler was called and state was updated
      # This will depend on your actual implementation
      # For example, if clicking roll dice causes dice to be displayed:
      assert has_element?(view, ".dice-result")

      # Or if the button gets disabled after clicking:
      assert view
             |> element(".roll-dice-btn")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.attribute("disabled") == [""]
    end
  end
end
