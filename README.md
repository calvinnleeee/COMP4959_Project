# Monopoly: Vancouver Housing Market 

## 🏫 BCIT COMP4959 Project

Elixir / Phoenix implementation of the board game Monopoly.

## 💻 How To Run
To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## 🎮 How to Play

## 🎲 Game Rule
- careate a game and enter a lobby
- 2-6 players, each with a specific starting token (car, hat, thimble, shoe, etc.).
- Loop through users, on each user’s turn
    - Roll 2 dice
    - Move by amount shown on dice (if you roll double, take turn and roll again. If you roll double for a third time in a row, go directly to jail).
      -  Passing GO grants the player a monetary bonus of ($200).
    - On board space
        - If property space:
          - https://en.wikibooks.org/wiki/Monopoly/Properties_reference 
        - Option to buy if it is not owned. If you don’t want to buy, it goes to an auction for all the players.
        - If it is owned, pay rent to the owner.
      - If WATER WORKS or ELECTRIC COMPANY:
          - https://monopoly.fandom.com/wiki/Utility 
          - You may purchase the utility if it is not owned.
          - If it is owned, you must pay 4 times your dice roll to the owner if they own only that utility. If they own both, you must pay 10 times your dice roll.
      - If RAILROADS ( WE MAKING THEM REGULAR ):
          - https://monopoly.fandom.com/wiki/Railroads 
          - You may purchase the railroad if it is not owned.
          - If it is owned, you must pay the amount owed in accordance with the amount of stations owned by the owner of the station you landed on.
      - If COMMUNITY CHEST, draw a community chest card.
        - https://monopoly.fandom.com/wiki/Community_Chest 
      - If CHANCE, draw a chance card.
        - https://monopoly.fandom.com/wiki/Chance#Cards 
      - If the tile is JAIL, only visit.
        - https://monopoly.fandom.com/wiki/Jail 
        - If you were sent to jail by card effect or landing on ‘Go To Jail’, you stay in jail for 3 turns.
        - If jailed by an effect, player can escape by: 
          - Paying the fine ($50)
          - Rolling doubles on any of the three turns in jail. Move forward using the result, but the player doesn’t get an extra throw.
          - Using a ‘Get out of jail free’ card (drawn from either card pile)
        - Player WILL leave the jail after the third throw and pay the fine if the third throw is not a double.
        - If not ‘sent to Jail’, players that reach this space incur no penalty and take a break.
      - If FREE PARKING space, rest for free.
      - If GO TO JAIL, go to jail
      - If LUXURY TAX, pay ($100)
      - If INCOME TAX, pay (10%) OR ($100), whichever is lower
    - Hand over the turn to the next player

## 🔀 Game Logic Flowchart

## 👥 Team Members

| Frontend | Backend | QA | UI/UX | PM |
|----------|----------|----------|----------|----------|
| Caleb Chiang [![Github](./github-logo.png)](https://github.com/calebchiang)  | Abdulqaidr Abuharrus [![Github](./github-logo.png)](https://github.com/Abdo-Abuharrus211)    | Derek Tran [![Github](./github-logo.png)](https://github.com/ddderekk)      | Alex Deschenes| Calvin Lee [![Github](./github-logo.png)](https://github.com/calvinnleeee/)|
| Echo Wang [![Github](./github-logo.png)](https://github.com/EchooWww)    | Clement Quanch [![Github](./github-logo.png)](https://github.com/Clement-Quach)    | Flora Deng [![Github](./github-logo.png)](https://github.com/FloraDeng00)   | Filip Budd [![Github](./github-logo.png)](https://github.com/filipbudd/) | Jesse McKenzie [![Github](./github-logo.png)](https://github.com/JDMCK)|
| Princeton Dychinco [![Github](./github-logo.png)](https://github.com/pdychinco)    | Irix Xu [![Github](./github-logo.png)](https://github.com/IrisWRX)    | Inez Yoon [![Github](./github-logo.png)](https://github.com/Inez-y)       | 
| Quincy Wong [![Github](./github-logo.png)](https://github.com/phoenixalpha204)    | Jaiden Duncan    | Niko Wang [![Github](./github-logo.png)](https://github.com/nzzzzzw)       | 
| Saeyoung Park [![Github](./github-logo.png)](https://github.com/eesope/)    | Joanne Ho   | Richard Maceda [![Github](./github-logo.png)](https://github.com/Organic-156)      | 
|    | Matthew Yoon    |        | 
|     | Nathan Yau [![Github](./github-logo.png)](https://github.com/nathan-yau)    |        | 
|     | Erick Deau [![Github](./github-logo.png)](https://github.com/eric-deau)   |        | 


## 💡 Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
