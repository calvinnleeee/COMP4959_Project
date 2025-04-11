defmodule MonopolyWeb.Components.BuyModalTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import MonopolyWeb.CoreComponents
  alias MonopolyWeb.Components.BuyModal

  test "renders buy modal with property info" do
    property = %{
      name: "Boardwalk",
      buy_cost: 400
    }

    html = render_component(&MonopolyWeb.Components.BuyModal.buy_modal/1, %{
      id: "buy-modal",
      show: true,
      property: property
    })

    # assert html =~ "Buy Confirmation" 
    assert html =~ "Boardwalk"
    assert html =~ "$400"
  end
end
