# Team Fortress Jumper
A small demo built in Godot 4.1+ that attempts to recreate how it feels to rocket-jump around in **Team Fortress 2**.
As it stands, it's pretty close. Collisions are quite broken. Things like bunny-hopping can also be intentionally turned on (they're pretty fun to mess around with).

<h3>Showcases:</h3>
<p><img width="33%" src="https://github.com/user-attachments/assets/72130acc-0033-4033-b286-7181e6e94f14"><img width="33%" src="https://github.com/user-attachments/assets/9e430c6f-c1f2-4a89-9147-a2848ff3cdca"><img width="33%" src="https://github.com/user-attachments/assets/a9cccff5-2f6e-483d-b398-90e13b7b4dae"></p>

<sup> Do not judge this code quality.</sup>

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
| **R** | Charge
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
| **ALT** + **F3** | Toggle position from eyes
| **CTRL** + **F3** | Toggle Hammer Units/Meters
| **SHIFT** + **F3** | Toggle explosion radius & collisions display
| **F** | Spawn fake player
| **M** | Mute audio
| **K** | Set rotation's yaw to 89°
| **Shift** + **K** | Set rotation's pitch to 0°


## Credits

My [Twitter](https://twitter.com/DoodlingMicky) and [Bluesky](https://bsky.app/profile/mickeon.bsky.social).

This project is primarily based off the work of aneacsu [in this archived blog](https://web.archive.org/web/20240408190842/https://aneacsu.com/blog/2023/04/09/quake-movement-godot), as well as my prior experience with [Team Fortress Unity](https://www.youtube.com/watch?v=4WNybhStAE0).

- Maps ripped through [GodotVMF](https://github.com/H2xDev/GodotVMF) and [BSPSRC](https://github.com/ata4/bspsrc).
- [`pl_minepit`](https://gamebanana.com/mods/71709) created by [Csand1](https://gamebanana.com/members/264279)
- Sound effects ripped and organized by [Broly9990](https://www.sounds-resource.com/submitter/Broly9990/), [Cooper B. Chance](https://www.sounds-resource.com/submitter/Cooper+B.+Chance/), [Irockz](https://www.sounds-resource.com/submitter/Irockz/), [KIZ](https://www.sounds-resource.com/submitter/KIZ/), [Undeadbraindead](https://www.sounds-resource.com/submitter/Undeadbraindead/):
	<br>at the [Sounds Resource](https://www.sounds-resource.com/pc_computer/tf2/sound/18547/);
- Animations created/ported by [DJTHED](https://www.youtube.com/c/djthed);
- [Godot Engine](https://godotengine.org/) for allowing this;
- The [Team Fortress 2](https://www.teamfortress.com/) development team for creating a masterpiece;
- [Valve Software](https://www.valvesoftware.com/it/) for owning most of the used assets.

