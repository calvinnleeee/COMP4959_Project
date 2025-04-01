defmodule MonopolyWeb.BoardLive do
  @moduledoc """
  The VHM board which communicates with the backend Game server.
  """
  use MonopolyWeb, :live_view
  alias GameObjects.Game

  # Connect the player, sub to necessary PubSubs
  # State includes the game state, player's id, and player's struct
  # Step starts at roll_dice each turn with other steps after e.g. buy property
  def mount(params, _session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "game_state")
    {:ok, game} = Game.get_state()
    id = Map.get(params, "id")
    player = Enum.find(game.players, fn player -> player.id == id end)
    {:ok, assign(socket, game: game, id: id, player: player, step: "roll_dice")}
  end

  # Broadcasted by Game.roll_dice()
  def handle_info({:game_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # No backend yet
  def handle_info({:turn_ended, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # Broadcasted by Game.play_card()
  def handle_info({:card_played, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # When starting turn, player first clicks roll dice button
  def handle_event("roll_dice", _params, socket) do
    assigns = socket.assigns

    # Verify that it is the player's turn
    if assigns.game.current_player == assigns.player do
      # Call the backend roll_dice endpoint
      {:ok, {dice, _sum, double}, _new_pos, new_loc, new_game} =
        Game.roll_dice(assigns.id)
      player = new_game.current_player
      socket = assign(socket, player: player)

      # Offer player option to buy property they landed on
      if Enum.member?(
          [
            "brown", "red", "light blue", "pink", "orange",
            "yellow", "green", "blue", "railroad", "utility"
          ],
          new_loc.type
        ),
        do: new_game = offer_property(new_loc)

      # If player did not roll doubles, or is in jail, disable rolling dice
      if !double || player.in_jail, do: socket = assign(socket, step: "options")

      # TODO: the player might have gotten a card? Figure out if anything needs to be handled
      # TODO: special handling for if player is in jail

      socket = assign(socket, game: new_game)
    end

    {:noreply, socket}
  end

  # Let player choose whether to buy property they landed on
  # If player says yes and has funds, call backend (not yet impl)
  defp offer_property(tile, game) do
    game
  end

  def render(assigns) do
    ~H"""
    <div>
      <button
        phx-click="roll_dice"
        disabled={
          @game.current_player != @player &&
          @step == "roll_dice"
        }
      >
        Roll Dice
      </button>
      <br><br>
      <p><%= inspect(@player) %></p>
      <p><%= inspect(@game) %></p>
    </div>
    """
  end
end
