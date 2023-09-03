# tModLoader

## From their [GitHub](https://github.com/StarryPy/StarryPy3k)

StarryPy3k is the successor to StarryPy. StarryPy is a plugin-driven Starbound server wrapper that adds a great deal of functionality to Starbound. StarryPy3k is written using asyncio in Python 3.11.

## Install notes

Due to rate limiting the console on the panel cannot keep up with the game console and the build will complete before the panel console may show it. Reloading the console will load it to the latest part of the log.

## Server Ports

StarryPy3K required ports to run

| Port    | default |
|---------|---------|
| Game    | 21024   |

## Extra Information

If you want to download mods in the console, the startup command has to be changed.

New startup:
`python3 .\server.py`

This will remove the autocreate function, and will thus allow you to download mods and generate world.
Afterwards, you can change it back with the correct world name to start automatic. Word name is set in the configuration panel.
