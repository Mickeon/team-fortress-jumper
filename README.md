# Team Fortress Jumper
A small demo built in Godot 4.1+ that attempts to recreate how it feels to rocket-jump around in **Team Fortress 2**.
As it stands, it's pretty close. Collisions are almost entirely broken. Things like bunny-hopping may also be intentionally turned on (they're pretty fun to mess around with).

<img width="45%" alt="Team Fortress Jumper Harvest preview" src="https://github.com/Mickeon/team-fortress-jumper/assets/66727710/2b6b756d-82e6-4af9-9e2f-8cf5a100eed8">
<img width="45%" alt="Team Fortress Jumper Test map preview" src="https://github.com/Mickeon/team-fortress-jumper/assets/66727710/7846da8f-d52c-46cc-882e-41141fe12f63">

<sup> Do not judge this code quality. </sup>

This repository has not been originally designed to be visible by the public, but I'm putting it out there. It could be useful as a general point of reference. 
Full support for this demo, as well as additional features _(such as multiplayer)_ should **not** be taken for granted.

You can try a **considerably** stripped out version of this project on a Chromium web browser by [clicking here](https://mickeon.itch.io/team-fortress-jumper).
Alternatively, download a build from [the releases](https://github.com/Mickeon/team-fortress-jumper/releases).

## Controls

**Beware: Some actions may become outdated.**

#### Basic:
| Key | Action |
| :-: | --- |
| **WASD** | Move
| **Jump** | Jump
| **Shift** or **CTRL** | Crouch
| **Left Click** | Use Weapon
| **R** | Charge!!
| **1** | Switch to Rocket Launcher
| **2** | Switch to Shotgun
| **3** | Switch to Shovel
| **4** | Switch to Grenade Launcher


#### Selection:
| Key | Action | ... |
| :-: | --- | --- |
| **\\** | Restart current scene | ... _It's the button below **ESC**_
| **F2** | Change map to `itemtest`
| **CTRL** + **F2** | Change map to `koth_harvest_final` | Not available in web demo.<br>This can take a while to load.
| **SHIFT** + **F2** | Change map to `pl_minepit` | Not available in web demo.<br>This can take a while to load.

#### Debugging:
| Key | Action |
| :-: | --- |
| **F1** | Toggle first person model
| **F3** | Toggle debug label
| **F4** | Toggle bunny hopping
| **F5** | Change camera mode
| **N** or **E** | Toggle noclip
| **Page Up/Down** | Change time scale
| **CTRL** + **F3** | Toggle Hammer Units/Meters
| **SHIFT** + **F3** | Toggle explosion radius & collisions display
| **F** | Spawn fake player
| **M** | Mute audio


## Credits

My Twitter: https://twitter.com/DoodlingMicky

This project is primarily based off the work of aneacsu [in this blog](https://aneacsu.com/blog/2023/04/09/quake-movement-godot)(See also [this video](https://www.youtube.com/watch?v=ssU6ec_um78)), as well as my prior experience with [Team Fortress Unity](https://www.youtube.com/watch?v=4WNybhStAE0).

- Maps ripped through [GodotVMF](https://github.com/H2xDev/GodotVMF) and [BSPSRC](https://github.com/ata4/bspsrc).
- [`pl_minepit`](https://gamebanana.com/mods/71709) created by [Csand1](https://gamebanana.com/members/264279)
- Sound effects ripped and organized by [Broly9990](https://www.sounds-resource.com/submitter/Broly9990/), [Cooper B. Chance](https://www.sounds-resource.com/submitter/Cooper+B.+Chance/), [Irockz](https://www.sounds-resource.com/submitter/Irockz/), [KIZ](https://www.sounds-resource.com/submitter/KIZ/), [Undeadbraindead](https://www.sounds-resource.com/submitter/Undeadbraindead/):
	<br>at the [Source Resource](https://www.sounds-resource.com/pc_computer/tf2/sound/18547/);
- Animations created/ported by [DJTHED](https://www.youtube.com/c/djthed);
- [Godot Engine](https://godotengine.org/) for allowing this;
- The [Team Fortress 2](https://www.teamfortress.com/) development team for creating a masterpiece;
- [Valve Software](https://www.valvesoftware.com/it/) for... owning a lot of the used assets.

