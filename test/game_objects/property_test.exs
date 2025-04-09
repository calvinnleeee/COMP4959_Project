defmodule GameObjects.PropertyTest do
  use ExUnit.Case
  alias GameObjects.Property

  defmodule Player do
  	defstruct [:id, :name, :money, :sprite_id, :position, :properties, :cards, :in_jail, :jail_turns]
	def get_properties(player) do
        player.properties
    end
  end


  describe "new/8" do
  	test "create new property with correct types" do
  		property = Property.new(0, "test", "brown", 100, [100, 200], 2, 50, 0)
  		assert property.id == 0
  		assert property.name == "test"
  		assert property.type == "brown"
  		assert property.buy_cost == 100
  		assert property.rent_cost == [100, 200]
  		assert property.upgrades == 2
  		assert property.house_price == 50
  		assert property.hotel_price == 0
		assert property.owner == nil
  	end
	end

	describe "set_owner/2" do
		test "set owner for unowned property" do
			player = %Player{id: 1, name: "Test", money: 1000, sprite_id: "sprite-1", position: 0,
			cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, 200, 2, 50, 0)
			result_property = Property.set_owner(property, player)
			assert result_property.owner == player.id
		end

		test "set owner for owned property" do
			player1 = %Player{id: 1, name: "DONKEY", money: 1000, sprite_id: "sprite-1",position: 0,
			cards: [], in_jail: true, jail_turns: 0}
			player2 = %Player{id: 1, name: "KONGA", money: 0, sprite_id: "sprite-2",position: 0,
			cards: [], in_jail: false, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, 200, 2, 50, 0)

			property = Property.set_owner(property, player1)
			assert property.owner == player1.id
			property = Property.set_owner(property, player2)
			assert property.owner == player2.id
		end
	end

	describe "get_owner/1" do
		test "get_owner with no owner" do
			property = Property.new(0, "test", "brown", 100, 200, 2, 50, 0)
			assert Property.get_owner(property) == nil
		end

		test "get_owner with some owner" do
			player1 = %Player{id: 1, name: "DONKEY", money: 1000, sprite_id: "sprite-1",position: 0,
			cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, 200, 2, 50, 0)

			property = Property.set_owner(property, player1)
			assert Property.get_owner(property) == player1.id
		end
	end

	test "get_id(property)" do
		property = Property.new(1000, "test", "brown", 100, 200, 2, 50, 0)
		assert Property.get_id(property) == 1000
	end

	test "get_name(property)" do
		property = Property.new(1000, "Boardwalk", "Navy Blue", 100, 200, 2, 50, 0)
		assert Property.get_name(property) == "Boardwalk"
		assert Property.get_name(property) != "boardwalk"
	end

	test "get_type(property)"  do
		property = Property.new(1000, "Boardwalk", "Navy Blue", 100, 200, 2, 50, 0)
		assert Property.get_type(property) == "Navy Blue"
		assert Property.get_name(property) != "navy blue"
	end

	describe "get_rent_list(property)" do
		test "Empty array as rent_cost list" do
			property = Property.new(0, "test", "brown", 100, [], 2, 50, 0)
			assert Property.get_rent_list(property) == []
		end

		test "Single element array rent_cost list" do
			property = Property.new(0, "test", "brown", 100, [300], 2, 50, 0)
			assert Property.get_rent_list(property) == [300]
		end

		test "Multi element array rent_cost list" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300, 0], 2, 50, 0)
			assert Property.get_rent_list(property) == [100, 200, 300, 0]
		end
	end

	describe "get_current_rent(property)" do
		test "No upgrades" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 0, 50, 0)
			assert Property.get_current_rent(property) == 100
		end

		test "One upgrade" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 1, 50, 0)
			assert Property.get_current_rent(property) == 200
		end

		test "Final upgrade" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 2, 50, 0)
			assert Property.get_current_rent(property) == 300
		end
	end

	test "get_upgrades(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		assert Property.get_upgrades(property) == 3
	end

	test "set_upgrade(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		assert Property.get_upgrades(property) == 3
		property = Property.set_upgrade(property, 5)
		assert Property.get_upgrades(property) == 5
	end

	test "inc_upgrade(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		assert Property.get_upgrades(property) == 3
		property = Property.inc_upgrade(property)
		assert Property.get_upgrades(property) == 4
	end

	test "dec_upgrade(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		assert Property.get_upgrades(property) == 3
		property = Property.dec_upgrade(property)
		assert Property.get_upgrades(property) == 2
	end

	test "get_house_price(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		assert Property.get_house_price(property) == 50
	end

	test "get_hotel_price(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
		assert Property.get_hotel_price(property) == 51
	end

	test "set_house_price(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 0)
		property = Property.set_house_price(property, 25)
		assert Property.get_house_price(property) == 25
	end

	test "set_hotel_price(property)" do
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
		property = Property.set_hotel_price(property, 53988)
		assert Property.get_hotel_price(property) == 53988
	end

	describe "buy_property(property, player)" do
		test "no owned properties"do
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			result = Property.buy_property(property, player)
			assert result = [property]
		end

		test "one owned unrelated property"do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "blue", 100, [100, 200, 300], 3, 50, 51)
			[old_property, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id}
		end

		test "two owned only one related color"do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			property2 = Property.new(0, "test", "green", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "green", 100, [100, 200, 300], 0, 50, 51)
			[old_property1, old_property2, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id}
			assert old_property2.upgrades == 0
			assert added_property.upgrades == 0
		end

		test "one brown already owned"do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(0, "test", "green", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "brown", 100, [100, 200, 300], 0, 50, 51)
			[old_property1, old_property2, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id, upgrades: 1}
			assert old_property1.upgrades == 1
			assert old_property2.upgrades == 0
		end

		test "one blue already owned"do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 1, 50, 51)
			property2 = Property.new(0, "test", "green", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			[old_property1, old_property2, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id, upgrades: 1}
			assert old_property1.upgrades == 2
			assert old_property2.upgrades == 0
		end

		test "two owned both related color not brown/blue"do
			property = Property.new(0, "test", "green", 100, [100, 200, 300], 1, 50, 51)
			property2 = Property.new(0, "test", "green", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "green", 100, [100, 200, 300], 1, 50, 51)
			[old_property1, old_property2, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id, upgrades: 2}
			assert old_property1.upgrades == 2
			assert old_property2.upgrades == 1
		end

		test "one utility owned already"do
			property = Property.new(0, "test", "utility", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(1, "test", "utility", 100, [100, 200, 300], 0, 50, 51)
			[old_property1, old_property2, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id, upgrades: 1}
			assert old_property1.upgrades == 1
			assert old_property2.upgrades == 0
		end

		test "two railroads owned already"do
			property = Property.new(0, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(1, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			property3 = Property.new(2, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property, property2, property3], cards: [], in_jail: true, jail_turns: 0}
			new_property = Property.new(3, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			[old_property1, old_property2, old_property3, added_property] = Property.buy_property(new_property, player)
			assert added_property == %{new_property | owner: player.id, upgrades: 2}
			assert old_property1.upgrades == 2
			assert old_property2.upgrades == 0
			assert old_property3.upgrades == 2
		end

	end

	test "buy_property_simple(property, player)"  do
		player = %Player{id: 1, name: "DONKEY", money: 1000, sprite_id: "sprite-1",position: 0,
		cards: [], in_jail: true, jail_turns: 0}
		property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
		property = Property.buy_property_simple(property, player)
		assert Property.get_owner(property) == player.id
	end

	describe "is_owned(property)" do
		test "is_owned not owned" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			assert !Property.is_owned(property)
		end

		test "is_owned is owned" do
			player = %Player{id: 1, name: "DONKEY", money: 1000, sprite_id: "sprite-1",position: 0,
			cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			property = Property.set_owner(property, player)
			assert Property.is_owned(property)
		end
	end

	describe "upgrade_set(property, player)" do
		test "empty properties list" do
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			assert Property.upgrade_set(property, player) == []
		end

		test "single unrelated property" do
			property2 = Property.new(0, "test", "blue", 100, [100, 200, 300], 3, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property2], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 3, 50, 51)
			assert Property.upgrade_set(property, player) == [property2]
		end

		test "single related property" do
			property2 = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property2], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			[updated_property] = Property.upgrade_set(property, player)
			assert updated_property.upgrades == 1
		end

		test "one related one unrelated property" do
			property2 = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			property3 = Property.new(0, "test2", "brown", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property2, property3], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			[updated_property1, updated_property2] = Property.upgrade_set(property, player)
			assert updated_property1.upgrades == 1
			assert updated_property2.upgrades == 0
		end

		test "multiple all related property" do
			property2 = Property.new(0, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			property3 = Property.new(0, "test2", "railroad", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property2, property3], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			[updated_property1, updated_property2] = Property.upgrade_set(property, player)
			assert updated_property1.upgrades == 1
			assert updated_property2.upgrades == 1
		end

		test "multiple all unrelated property" do
			property2 = Property.new(0, "test", "railroad", 100, [100, 200, 300], 0, 50, 51)
			property3 = Property.new(0, "test2", "railroad", 100, [100, 200, 300], 0, 50, 51)
			player = %Player{id: 1, name: "test", money: 1000, sprite_id: "sprite-1",position: 0,
			properties: [property2, property3], cards: [], in_jail: true, jail_turns: 0}
			property = Property.new(0, "test", "red", 100, [100, 200, 300], 0, 50, 51)
			[updated_property1, updated_property2] = Property.upgrade_set(property, player)
			assert updated_property1.upgrades == 0
			assert updated_property2.upgrades == 0
		end
	end

	describe "upgrade_set_list(property, list)" do
		test "All same type as given property" do
			player_property = Property.new(0, "test", "Brown", 100, [100, 200, 300], 0, 50, 51)
			property1 = Property.new(0, "test", "Brown", 100, [100, 200, 300], 1, 50, 51)
			property2 = Property.new(0, "test", "Brown", 100, [100, 200, 300], 10, 50, 51)
			property3 = Property.new(0, "test", "Brown", 100, [100, 200, 300], 3, 50, 51)
			properties = [property1, property2, property3]
			result = Property.upgrade_set_list(player_property, properties)
			assert Property.get_upgrades(Enum.at(result, 0)) == 2
			assert Property.get_upgrades(Enum.at(result, 1)) == 11
			assert Property.get_upgrades(Enum.at(result, 2)) == 4
		end

		test "All different type as given property" do
			player_property = Property.new(0, "test", "Brown", 100, [100, 200, 300], 0, 50, 51)
			property1 = Property.new(0, "test", "Blue", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(0, "test", "Railroad", 100, [100, 200, 300], 10, 50, 51)
			property3 = Property.new(0, "test", "Green", 100, [100, 200, 300], 3, 50, 51)
			properties = [property1, property2, property3]
			result = Property.upgrade_set_list(player_property, properties)
			assert Property.get_upgrades(Enum.at(result, 0)) == 0
			assert Property.get_upgrades(Enum.at(result, 1)) == 10
			assert Property.get_upgrades(Enum.at(result, 2)) == 3
		end

		test "Some same type as given property" do
			player_property = Property.new(0, "test", "Brown", 100, [100, 200, 300], 0, 50, 51)
			property1 = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(0, "test", "Brown", 100, [100, 200, 300], 10, 50, 51)
			property3 = Property.new(0, "test", "Brown", 100, [100, 200, 300], 3, 50, 51)
			property4 = Property.new(0, "test", "Railroad", 100, [100, 200, 300], 3, 50, 51)
			properties = [property1, property2, property3, property4]
			result = Property.upgrade_set_list(player_property, properties)
			assert Property.get_upgrades(Enum.at(result, 0)) == 0
			assert Property.get_upgrades(Enum.at(result, 1)) == 11
			assert Property.get_upgrades(Enum.at(result, 2)) == 4
			assert Property.get_upgrades(Enum.at(result, 3)) == 3
		end
	end

	describe "sell_upgrade(property)" do
		test "sell_upgrade 0 or 1 upgrades" do
			property1 = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 50, 51)
			property2 = Property.new(0, "test", "blue", 100, [100, 200, 300], 1, 50, 51)
			assert Property.sell_upgrade(property1) == {property1, 0}
			assert Property.sell_upgrade(property2) == {property2, 0}
		end

		test "sell_upgrade hotel upgrade" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 6, 50, 500)
			{result, price} = Property.sell_upgrade(property)
			assert Property.get_upgrades(result) == 5
			assert price == 500
		end

		test "sell_upgrade house upgrade" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 4, 300, 1)
			{result, price} = Property.sell_upgrade(property)
			assert Property.get_upgrades(result) == 3
			assert price == 300
		end
	end

	describe "build_upgrade(property)" do
		test "full set" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 6, 300, 1)
			assert Property.build_upgrade(property) == {property, 0}
		end

		test "5 upgrades" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 5, 300, 10)
			{property, cost} = Property.build_upgrade(property)
			assert Property.get_upgrades(property) == 6
			assert cost == 10
		end

		test "less than 5 more than 0 upgrades" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 3, 300, 10)
			{property, cost} = Property.build_upgrade(property)
			assert Property.get_upgrades(property) == 4
			assert cost == 300
		end

		test "no upgrades" do
			property = Property.new(0, "test", "blue", 100, [100, 200, 300], 0, 300, 10)
			assert Property.build_upgrade(property) == {property, 0}
		end
	end

	describe "charge_rent(property, dice)" do
		test "utility no upgrades" do
			property = Property.new(0, "test", "utility", 100, [100, 200, 300], 0, 300, 10)
			assert Property.charge_rent(property, 5) == 20
		end

		test "utility some upgrades" do
			property = Property.new(0, "test", "utility", 100, [100, 200, 300], 3, 300, 10)
			assert Property.charge_rent(property, 5) == 50
		end

		test "nonutility some upgrades" do
			property = Property.new(0, "test", "brown", 100, [100, 200, 300], 0, 300, 10)
			assert Property.charge_rent(property, 5) == 100
		end
	end

end
