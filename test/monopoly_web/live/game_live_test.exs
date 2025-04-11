defmodule MonopolyWeb.GameLiveTest do
  use MonopolyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "player dashboard" do
    test "displays player dashboard for current player", %{conn: conn} do
      # Navigate to the game page
      {:ok, view, _html} = live(conn, ~p"/game/game-1")

      # Assert that the dashboard contains expected elements
      assert has_element?(view, "#player-dashboard")
      assert has_element?(view, ".player-name") # Player name should be visible
      assert has_element?(view, ".money-amount") # Money amount should be visible
      assert has_element?(view, ".roll-dice-btn")
    end

    test "enables/disables buttons based on turn status", %{conn: conn} do
      # Start with the game
      {:ok, view, _html} = live(conn, ~p"/game/game-1")

      # Initially the roll button should be enabled
      refute has_element?(view, ".roll-dice-btn[disabled]")

      # Roll the dice
      view |> element(".roll-dice-btn") |> render_click()

      # After rolling, test if we got doubles
      if view |> has_element?(".doubles-notification") do
        # If we got doubles, the roll button should still be enabled
        refute has_element?(view, ".roll-dice-btn[disabled]")
      else
        # If we didn't get doubles, the roll button should be disabled
        assert has_element?(view, ".roll-dice-btn[disabled]")
      end

      # If the roll button is disabled, the end turn button should be enabled
      if has_element?(view, ".roll-dice-btn[disabled]") do
        refute has_element?(view, ".end-turn-btn[disabled]")
      end
    end

    test "clicking roll dice button triggers event", %{conn: conn} do
      # Start the game
      {:ok, view, _html} = live(conn, ~p"/game/game-1")

      # Click the roll dice button
      view |> element(".roll-dice-btn") |> render_click()

      # Verify dice result appears
      assert has_element?(view, ".dice-results-dashboard")

      # Check that one of the expected states is true
      assert has_element?(view, ".roll-dice-btn[disabled]") || has_element?(view, ".doubles-notification")
    end
  end
end
