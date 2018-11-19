[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=3LLQHP7FGQJWL&currency_code=USD)

# DruidConsumable
Powershifting Consumable use for Druids in Vanilla World of Warcraft.

This addon also requires you have either DruidBar or Luna Unit Frames addon installed. It also requires CerniesWonderfulFunctions (https://github.com/Cernie/CerniesWonderfulFunctions).

Author: Cernie


# Installation

Unzip the DruidConsumable folder into WoW directory Interface/Addons folder. Remove the -master from the folder name.

# Usage

To use DruidConsumable addon, create a macro that uses the following signature:

<code>/script DruidConsumable({options});</code>

Available options to pass as parameters:
- type
  - This is a string of the type of consumable you want to use.
  - Valid types are mana, health, sapper, juju, misc.
  - Note if using type='misc', the item parameter is required.
- item
  - This is a string of the item name you wish to use if using type='misc'.
- form
  - This is a string of the form you wish to powershift back into.
  - Valid forms are (Dire) Bear Form, Cat Form, Travel Form, Aquatic Form, Moonkin Form.
  - If nothing is passed to this parameter, the addon defaults to Cat Form.
- manaCutOff
  - This is a number of the mana level at which you wish to start using mana consumables.
  - This is used in conjunction with type='mana'.
- healthCutOff
  - This is a number of the health level at which you wish to start using health consumables.
  - This is used in conjunction with type='health'.
- percent
  - This is a number between 0 and 1 of the mana or health level at which you wish to start using mana/health consumables.
  - manaCutOff and healthCutOff will be used instead if either are passed as a parameter.
  - This is used in conjunction with type='health' or type='mana'.
  - If neither manaCutOff/healthCutOff nor percent is passed as a parameter, the addon defaults to percent=0.5 (50%).

# Examples
Example macro for Cat Form Mana Consumables:

<code>/script DruidConsumable({type='mana', form='Cat Form', manaCutOff=3500});</code>

Example macro for Bear Form Health Consumables:

<code>/script DruidConsumable({type='health', form='Dire Bear Form', percent=0.35});</code>

Example macro for Bear Form Misc tanking potion:

<code>/script DruidConsumable({type='misc', form='Dire Bear Form', item='Greater Stoneshield Potion'});</code>

Example macro for Cat Form Juju Flurry Consumable:

<code>/script DruidConsumable({type='juju', form='Cat Form'});</code>

Example macro for Cat Form Goblin Sapper Charge Consumable:

<code>/script DruidConsumable({type='sapper', form='Cat Form'});</code>
