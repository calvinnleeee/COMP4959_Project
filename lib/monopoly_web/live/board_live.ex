defmodule MonopolyWeb.BoardLive do
  use MonopolyWeb, :live_view

  def mount(params, _session, socket) do
    Phoenix.PubSub.subscribe(Monopoly.PubSub, "board")
    {:ok, game} = GameObjects.Game.get_state()
    id = Map.get(params, "id")
    player = Enum.find(game.players, fn player -> player.id == id end)
    {:ok, assign(socket, game: game, id: id, player: player)}
  end

  def handle_info({:turn, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("turn", _params, socket) do
    assigns = socket.assigns
    if assigns.game.current_player == assigns.player do
      IO.puts(assigns.id <> " taking a turn")
      game = %{assigns.game | current_player: Enum.random(assigns.game.players)}
      socket = assign(socket, game: game)
      Phoenix.PubSub.broadcast(Monopoly.PubSub, "board", {:turn, game})
    end
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="turn" disabled={@game.current_player != @player}>
        Take Your Turn
      </button>
      <br><br>
      <p class="state"><%= inspect(@game) %><%= inspect(@player) %></p>
    </div>
    """
  end
end
