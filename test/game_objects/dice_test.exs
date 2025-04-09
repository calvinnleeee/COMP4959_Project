defmodule GameObjects.DiceTest do
  use ExUnit.Case
  alias GameObjects.Dice
  
  describe "roll()" do
  	test "roll not double" do 
		:rand.seed(:exs1024, {5, 3, 1})
		{{d1, d2}, sum, is_doubles} = Dice.roll()
		assert d1 == 5
		assert d2 == 3
		assert sum == 8
		assert !is_doubles
	end
	
	test "roll double" do 
		:rand.seed(:exs1024, {5, 5, 5})
		{{d1, d2}, sum, is_doubles} = Dice.roll()
		assert d1 == 6
		assert d2 == 6
		assert sum == 12
		assert is_doubles
	end
  end
  
  describe "check_for_jail(turns_taken, is_doubles)" do
  	test "not double" do
  		assert Dice.check_for_jail(3, false) == false
  	end
  	
  	#assume turns_taken increments from 0 after first double
 	test "double first turn" do
  		assert Dice.check_for_jail(1, true) == false
  	end
  	
	test "double second turn" do
  		assert Dice.check_for_jail(2, true) == false
  	end
  	
	test "double third turn" do
  		assert Dice.check_for_jail(3, true) == true
  	end
  end
  
  describe "jail_roll(jail_turns)" do
  	test "roll double first turn" do
  		:rand.seed(:exs1024, {5, 5, 5})
  		assert Dice.jail_roll(0) == {:out_of_jail, {6, 6}, 12}
  	end
  	
	test "roll double second turn" do
  		:rand.seed(:exs1024, {5, 5, 5})
		assert Dice.jail_roll(1) == {:out_of_jail, {6, 6}, 12}
  	end
  	
  	test "roll double third turn" do
  		:rand.seed(:exs1024, {5, 5, 5})
		assert Dice.jail_roll(2) == {:out_of_jail, {6, 6}, 12}
  	end
  	
  	test "not double first turn" do
  		:rand.seed(:exs1024, {5, 3, 1})
  		assert Dice.jail_roll(0) == {:stay_in_jail, {5, 3}, 8}
  	end
  	
  	test "not double second turn" do
		:rand.seed(:exs1024, {5, 3, 1})
  		assert Dice.jail_roll(1) == {:stay_in_jail, {5, 3}, 8}
  	end
  	
  	test "no doubles third turn" do
  		:rand.seed(:exs1024, {5, 3, 1})
  		assert Dice.jail_roll(2) == {:failed_to_escape, {5, 3}, 8}
  	end
  end
	
end
