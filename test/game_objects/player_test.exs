# Generated player_text
defmodule GameObjects.PlayerTest do
  use ExUnit.Case
  alias GameObjects.Player

  # Hardcoded test
  @player_id "albert123"
  @player_name "Albert"
  @sprite_id 1

  # Basic setup test for hardcoded test : OK
  setup do
    player = Player.new(@player_id, @player_name, @sprite_id)
    %{player: player}
  end

end
