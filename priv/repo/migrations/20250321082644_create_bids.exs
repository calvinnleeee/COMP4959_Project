defmodule Monopoly.Repo.Migrations.CreateBids do
  use Ecto.Migration

  def change do
    create table(:bids) do
      add :player, :string
      add :bid_price, :integer
      add :property_prices, :string

      timestamps(type: :utc_datetime)
    end
  end
end
