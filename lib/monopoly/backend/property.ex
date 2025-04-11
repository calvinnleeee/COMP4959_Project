defmodule GameObjects.Property do
  alias GameObjects.Player

  @moduledoc """
  This modules represents Properties. this module contains what a property can do and have

  owner field is either nil or a Player struct. if the owner is nil, the property is not owned by anyone. if the owner is a Player struct, the property is owned by that player.
  id: the id of the property. will be used to apply functions to properties.
  name: the name to of the property to be displayed
  type: field refers to the group of properties. for example "brown", "blue", "railroad", "utility", etc used for when calculating rent when a set is made
  buy_cost: the cost to purchase the property
  rent_cost: a list of integers that represent rental costs. 0th index of the list is base rent, 1st index is rent with a full set, 2,3,4,5 are houses, 6 is hotel.
  upgrades: an integer from 0-7 that represents the number of houses or hotels on the property. 0 is no houses, 1 is full set, 2,3,4,5 is house, 6 is a hotel.
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :type,
    :buy_cost,
    :rent_cost,
    :upgrades,
    :house_price,
    :hotel_price,
    :owner
  ]

  @property_path Path.join(:code.priv_dir(:monopoly), "data/properties.json")
  @doc """
  Initializes the list of properties from the properties.json file.

  Each property will be parsed using `parse_property/1`.
  """
  def init_property_list do
    @property_path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(&parse_property/1)
  end

  def parse_property(%{
        "id" => id,
        "name" => name,
        "type" => type,
        "buy_cost" => buy_cost,
        "rent_cost" => rent_cost,
        "upgrades" => upgrades,
        "house_price" => house_price,
        "hotel_price" => hotel_price
      }) do
    new(id, name, type, buy_cost, rent_cost, upgrades, house_price, hotel_price)
  end

  @doc """
   id: the id of the property. will be used to apply functions to properties.
  name: the name to of the property to be displayed
  type: field refers to the group of properties. for example "brown", "blue", "railroad", "utility", etc used for when calculating rent when a set is made
  buy_cost: the cost to purchase the property
  rent_cost: a list of integers that represent rental costs. 0th index of the list is base rent, 1st index is rent with a full set, 2,3,4,5 are houses, 6 is hotel.
  upgrades: an integer from 0-7 that represents the number of houses or hotels on the property. 0 is no houses, 1 is full set, 2,3,4,5 is house, 6 is a hotel.
  house_price: the price to buy a house
  hotel_price: the price to buy a hotel
  returns a property struct
  """
  @spec new(
          id :: integer,
          name :: String.t(),
          type :: String.t(),
          buy_cost :: integer,
          rent_cost :: [integer],
          upgrades :: integer,
          house_price :: integer,
          hotel_price :: integer
        ) :: %__MODULE__{}
  def new(id, name, type, buy_cost, rent_cost, upgrades, house_price, hotel_price) do
    %__MODULE__{
      id: id,
      name: name,
      type: type,
      buy_cost: buy_cost,
      rent_cost: rent_cost,
      upgrades: upgrades,
      house_price: house_price,
      hotel_price: hotel_price,
      owner: nil
    }
  end

  # FUNCTIONS TO GET AND SET FIELDS

  @doc """
  function to set the owner of the property. returns a new property struct with the owner field set to the owner.
  this funciton does not add the property to the players struct.
  uses get_pid to get the pid of the player
  """
  def set_owner(property, player) do
    if player != nil do
      %__MODULE__{property | owner: player.id}
    else
      %__MODULE__{property | owner: nil}
    end
  end

  @doc """
  function to get the owner of the property. returns the pid of the owner
  """
  def get_owner(property) do
    property.owner
  end

  def get_id(property) do
    property.id
  end

  def get_name(property) do
    property.name
  end

  @doc """
    function to get the type of the property. returns the type of the property
    the type of the property is the set it belongs to. for example "brown", "blue", "railroad", "utility", etc used for when calculating rent when a set is made
    this returns a string
  """
  def get_type(property) do
    property.type
  end

  def get_buy_cost(property) do
    property.buy_cost
  end

  def get_rent_list(property) do
    property.rent_cost
  end

  def get_current_rent(property) do
    Enum.at(property.rent_cost, property.upgrades, 0)
  end

  def get_upgrades(property) do
    property.upgrades
  end

  def set_upgrade(property, upgrade) do
    %__MODULE__{property | upgrades: upgrade}
  end

  def inc_upgrade(property) do
    %__MODULE__{property | upgrades: property.upgrades + 1}
  end

  def dec_upgrade(property) do
    %__MODULE__{property | upgrades: property.upgrades - 1}
  end

  def get_house_price(property) do
    property.house_price
  end

  def get_hotel_price(property) do
    property.hotel_price
  end

  def set_hotel_price(property, price) do
    %__MODULE__{property | hotel_price: price}
  end

  def set_house_price(property, price) do
    %__MODULE__{property | house_price: price}
  end

  # FUNCTIONS TO WORK WITH PROPERTY

  @doc """
  function to buy a property and return that property at the end. this function does not handle money.
  if you would like to charge for the property accordingly, you can call the get_buy_cost function and subtract that from the player's money

  goes through the player and checks each property for if that player has the whole set.

  """
  def buy_property(property, player) do
    player_properties = Player.get_properties(player)
    count = Enum.count(player_properties, fn x -> get_type(x) == get_type(property) end)

    cond do
      count == 1 and get_type(property) == "brown" ->
        property = set_owner(property, player)
        player_properties = Player.get_properties(Player.add_property(player, property))
        upgrade_set_list(property, player_properties)

      count == 1 and get_type(property) == "blue" ->
        property = set_owner(property, player)
        player_properties = Player.get_properties(Player.add_property(player, property))
        upgrade_set_list(property, player_properties)

      count == 1 and get_type(property) == "utility" ->
        property = set_owner(property, player)
        player_properties = Player.get_properties(Player.add_property(player, property))
        upgrade_set_list(property, player_properties)

      count >= 1 and get_type(property) == "railroad" ->
        updated_property = set_owner(property, player)

        # Adding the new property
        railroad_count = count
        player_properties = Player.get_properties(Player.add_property(player, updated_property))

        new_properties =
          Enum.map(player_properties, fn r ->
            if r.type == "railroad" do
              set_upgrade(r, railroad_count)
            else
              r
            end
          end)

        new_properties

      count == 2 ->
        property = set_owner(property, player)
        player_properties = Player.get_properties(Player.add_property(player, property))
        upgrade_set_list(property, player_properties)

      true ->
        property = set_owner(property, player)
        player = Player.add_property(player, property)
        Player.get_properties(player)
    end
  end

  @doc """
  function to buy a property and return that property. this function does not handle money.
  if you would like to charge for the property accordingly, you can call the get_buy_cost function and subtract that from the player's money
  this function is a simpler version of buy_property. this function does not check for sets and upgrades. it just sets the owner of the property to the player
  """
  def buy_property_simple(property, player) do
    set_owner(property, player)
  end

  @doc """
  function to check if this property is bought by a player. returns true if the property has an owner, false otherwise
  """
  def is_owned(property) do
    property.owner != nil
  end

  @doc """
  function to take in a player and a property and upgrade all properties of that type to the next level. returns a list of properties
  """
  def upgrade_set(property, player) do
    player_properties = Player.get_properties(player)

    player_properties =
      Enum.map(player_properties, fn x ->
        if get_type(x) == get_type(property) do
          inc_upgrade(x)
        else
          x
        end
      end)

    player_properties
  end

  @doc """
  alternate function to upgrade_set. takes a list of properties and parese it and upgrades all properties of that same type
  returns a list of properties
  """
  def upgrade_set_list(property, list) do
    Enum.map(list, fn x ->
      if get_type(x) == get_type(property) do
        __MODULE__.inc_upgrade(x)
      else
        x
      end
    end)
  end

  @doc """
  function to sell a property. returns a tuple with the property and the amount of money the player should receive.
  this function does not handle money only returns the amount owed to who ever called this function.

  """
  def sell_upgrade(property) do
    cond do
      property.upgrades == 0 || property.upgrades == 1 ->
        {property, 0}

      property.upgrades == 6 ->
        {set_upgrade(property, property.upgrades - 1), get_hotel_price(property)}

      true ->
        {set_upgrade(property, property.upgrades - 1), get_house_price(property)}
    end
  end

  @doc """
  function to build a house on a property. returns a tuple with the property and the amount of money the player should pay.
  this function does not handle money only returns the amount due to who ever called this function.


  if they have a full set, charge for house
  if they have 4 houses charge for hotel
  if they have a hotel, charge nothing
  if they do not have a full set, charge nothing
  """

  def build_upgrade(property) do
    cond do
      property.upgrades == 6 ->
        {property, 0}

      property.upgrades == 5 ->
        {set_upgrade(property, property.upgrades + 1), get_hotel_price(property)}

      property.upgrades >= 1 ->
        {set_upgrade(property, property.upgrades + 1), get_house_price(property)}

      true ->
        {property, 0}
    end
  end

  defp utility_rent(property, dice) do
    if property.upgrades == 0 do
      dice * 4
    else
      dice * 10
    end
  end

  @doc """
  alternate function to get the rent of a property by its stored index instead. does not do utilties
  """
  defp normal_rent(property) do
    Enum.at(property.rent_cost, property.upgrades, 0)
  end

  @doc """
  function to charge rent when a player lands on property.
  @param property: the property the player landed on
  @param dice: the sum of the dice roll as a number. needed to calculate for utilities rent
  """
  def charge_rent(property, dice) do
    if property.type == "utility" do
      utility_rent(property, dice)
    else
      normal_rent(property)
    end
  end
end
