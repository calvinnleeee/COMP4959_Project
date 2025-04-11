# dummy screen to redirect to after "Start Game" button is clicked
defmodule MonopolyWeb.GameDummy do
  use MonopolyWeb, :live_view

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-screen">
      <h1 class="text-4xl font-bold text-gray-800">Game Dummy Screen</h1>
    </div>
    """
  end
end
