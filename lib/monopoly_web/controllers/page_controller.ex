defmodule MonopolyWeb.PageController do
  use MonopolyWeb, :controller

  def game_lobby(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :game_lobby, layout: false)
  end
end
