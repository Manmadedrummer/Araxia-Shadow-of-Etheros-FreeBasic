# Araxia: Shadow of Etheros

A handcrafted, top-down 2D role-playing game engineered entirely from scratch in FreeBASIC. This project is a pure labor of love dedicated to the golden era of 90s console RPGs, built pixel-by-pixel without relying on modern commercial game engines. 

## The Custom Engine
Every system in Araxia is meticulously custom-coded to ensure an authentic retro experience while pushing the limits of the environment:
*   **Custom Asset Pipeline:** Graphics utilize bespoke `.MDT` sprite files loaded directly into memory via `BLOAD` commands.
*   **Old-School Rendering:** Visuals are drawn using classic tile maps and transparent `PUT` rendering for seamless character movement.
*   **Atmospheric Environments:** An integrated dynamic lighting system brings dungeons, towns, and overworld environments to life.

## Game Controls
Navigate the world and command your heroes in battle using classic keyboard inputs.

| Action | Key Binding | Description |
| :--- | :--- | :--- |
| **Move Up** | `Up Arrow` | Navigate north through menus or the world map. |
| **Move Down** | `Down Arrow` | Navigate south. |
| **Move Left** | `Left Arrow` | Navigate west. |
| **Move Right** | `Right Arrow` | Navigate east. |
| **Confirm / Interact** | `Z` or `Enter` | Talk to NPCs, open chests, and confirm battle commands. |
| **Cancel / Menu** | `X` or `ESC` | Close menus, cancel actions, or open the party screen. |

## Adventurer's Survival Guide

### Combat and Encounters
*   **Mind Your Steps:** The world relies on a hidden threat gauge. Moving across hostile terrain—like deep forests or dungeon floors—slowly builds this gauge until a turn-based battle triggers.
*   **Tactical Routing:** If your HP is dangerously low, stick to visually distinct marked paths or cleared roads where the encounter threat rate is drastically reduced.
*   **Equipment Matters:** Base stats are only half the battle. Always prioritize upgrading your weapons and armor at local shops; your damage output and survivability rely heavily on these equipment modifiers.

### Exploration Hints
*   **Complete the Bestiary:** There are 60 unique monsters scattered across the realm. Make sure to explore every corner of the overworld to encounter and log them all.
*   **Listen to the Environment:** The soundtrack dynamically shifts based on your location. A sudden change in the music often indicates an impending boss room or a dangerous new zone.
