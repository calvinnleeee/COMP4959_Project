# 🏘️ Vancouver Housing Market 

## 🏫 BCIT COMP4959 Project


  ✨ Ever dreamed of owning property in Vancouver? ✨

  Play **Vancouver Housing Market** with your friends and live out your real estate fantasies.

  Without the crushing mortgage, you'll start with $1,500, which is enough to buy several properties and a bucket of bluberries *just like our grandparents*!

  Buy up propertie**s** without a down payment, charge rent, and send your misbehaving buddies to jail... where there’s actually enough room to hold them.

  **Vancouver Housing Market** is inpired by the classic board game Monopoly, with an Elixir/Phoenix implementation.

  Now it’s your turn to make your dream come true—own your favourite neighbourhood! 


## 💻 How To Run

Play with your friends online:  
🌐 [Game Website](http://ec2-35-95-136-234.us-west-2.compute.amazonaws.com:4000/)

Or run it locally:  
🖥️ [localhost:4000](http://localhost:4000)



## 🎮 How to Play

1. Call your friends to join!

2. Visit [Game Website](http://ec2-35-95-136-234.us-west-2.compute.amazonaws.com:4000/) in your browser.

3. Click **Join the Lobby**  
   *(insert image here)*

4. Once everyone’s in, click **Start Game**  
   *(insert image here)*

5. On your turn, select from available buttons  
   *(insert image here)*

6. No need to do math—we’ve got that covered!

7. Wait for your friends’ turns  
   *(insert image here)*

8. Repeat until there’s only one player standing!  
   *(insert image here)*


## 🎲 Game Rule

- Create a game and enter a lobby.
- 2–6 players can join, each with a unique token (car, hat, thimble, shoe, etc.).
- Players take turns in a loop.

### On Your Turn:

- 🎲 Roll 2 dice
- 🚶 Move forward by that number
- 🎁 Passing **GO** grants $200

#### On the space you land:

- **Property Space**  
  - Option to buy if unowned. If declined, it goes to **auction**.
  - If owned, pay **rent** to the owner.  
  📚 [Property Reference](https://en.wikibooks.org/wiki/Monopoly/Properties_reference)

- **Utilities (Water Works, Electric Company)**  
  💡 [Utility Info](https://monopoly.fandom.com/wiki/Utility)  
  - Pay 4× dice roll if owner has one utility  
  - Pay 10× if they own both

- **Railroads**  
  🚆 [Railroads Info](https://monopoly.fandom.com/wiki/Railroads)  
  - Pay rent based on how many railroads the owner controls

- **Community Chest / Chance**  
  📬 Draw a card  
  - [Community Chest](https://monopoly.fandom.com/wiki/Community_Chest)  
  - [Chance](https://monopoly.fandom.com/wiki/Chance#Cards)

- **Jail**  
  🚔 [Jail Rules](https://monopoly.fandom.com/wiki/Jail)  
  - Just visiting? No problem.  
  - If sent to jail, you stay up to 3 turns. Escape options:
    - Pay $50
    - Roll doubles
    - Use a *Get Out of Jail Free* card

- **Free Parking** — Rest and relax  
- **Go to Jail** — Go directly to jail  
- **Luxury Tax** — Pay $100  
- **Income Tax** — Pay 10% or $100, whichever is lower

➡️ End your turn and pass to the next player.

## ⚙️ Play Flowchart

![Game playing flowchart](./readme_assets/play-flowchart.png)

## 🔀 Game Logic Flowchart
- ➕ Player Joins Game  

  ![Flowchart when a player joins game](./readme_assets/player_joins_game.png)

- ➖ Player Leaves Game  

  ![Flowchart when a player leaves game](./readme_assets/player_leaves_game.png)

- ✅ Player Ends Turn  

  ![Flowchart when a player ends turn](./readme_assets/player_ends_turn.png)

- 🎲 Player Takes Turn  

  ![Flowchart when a player takes turn](./readme_assets/player_takes_turn.png)

- 🃏 Player Lands on Card Tile  

  ![Flowchart when a player lands on card tile](./readme_assets/player_lands_on_card_tile.png)

- 🏠 Player Lands on Property  

  ![Flowchart when a player lands on property](./readme_assets/player_lands_on_property.png)

## 🧪 How to test / debug


### Install Dependencies
```bash
mix setup
```

### Run Tests
```
mix test
```
- *0 failures* = success!
- Add new tests in `/test` as `.exs` files if you need more unit tests

### Debug Locally
```
mix phx.server
```
or
```
iex -S mix phx.server
```

Then visit: [`localhost:4000`](http://localhost:4000)


## 📁 File Structure

## 🐛 Known Bugs

## 👥 Team Members

*Alphabetically ordered*

| Frontend | Backend | QA | UI/UX | PM |
|----------|----------|----------|----------|----------|
| Alex Deschenes | Abdulqaidr Abuharrus [![Github](./readme_assets/github-logo.png)](https://github.com/Abdo-Abuharrus211) | Derek Tran [![Github](./readme_assets/github-logo.png)](https://github.com/ddderekk) | Filip Budd [![Github](./readme_assets/github-logo.png)](https://github.com/filipbudd/) | Calvin Lee [![Github](./readme_assets/github-logo.png)](https://github.com/calvinnleeee/) |
| Caleb Chiang [![Github](./readme_assets/github-logo.png)](https://github.com/calebchiang) | Clement Quanch [![Github](./readme_assets/github-logo.png)](https://github.com/Clement-Quach) | Flora Deng [![Github](./readme_assets/github-logo.png)](https://github.com/FloraDeng00) | | Jesse McKenzie [![Github](./readme_assets/github-logo.png)](https://github.com/JDMCK) |
| Echo Wang [![Github](./readme_assets/github-logo.png)](https://github.com/EchooWww) | Irix Xu [![Github](./readme_assets/github-logo.png)](https://github.com/IrisWRX) | Inez Yoon [![Github](./readme_assets/github-logo.png)](https://github.com/Inez-y) | | |
| Princeton Dychinco [![Github](./readme_assets/github-logo.png)](https://github.com/pdychinco) | Jaiden Duncan | Niko Wang [![Github](./readme_assets/github-logo.png)](https://github.com/nzzzzzw) | | |
| Quincy Wong [![Github](./readme_assets/github-logo.png)](https://github.com/phoenixalpha204) | Joanne Ho | Richard Maceda [![Github](./readme_assets/github-logo.png)](https://github.com/Organic-156) | | |
| Saeyoung Park [![Github](./readme_assets/github-logo.png)](https://github.com/eesope/) | Matthew Yoon | | | |
|  | Nathan Yau [![Github](./readme_assets/github-logo.png)](https://github.com/nathan-yau) | | | |
|  | Erick Deau [![Github](./readme_assets/github-logo.png)](https://github.com/eric-deau) | | | |



## 💡 Learn more

### Phoenix Web Framework
  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

### Elixir
  * Official website: https://elixir-lang.org/
  * Guides: https://hexdocs.pm/elixir/introduction.html
  * Docs: https://elixir-lang.org/docs.html
  * Blog: https://elixir-lang.org/blog/ 

### Monopoly (boardgame)
  * Wikipedia: https://en.wikipedia.org/wiki/Monopoly_(game)
