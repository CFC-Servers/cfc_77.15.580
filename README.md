## CFC Section 580
Section 580 detects, alerts of, and responds to players who maliciously use net messages to harm a server.
Configuration is currently done from within the code, but will eventually be Convars.

Section 580 completely overwrites `net.Incoming` (vs. wrapping!) on the serverside, so if you have any other addons that do this, they won't play nicely.

This addon aims to be as performant and useful as possible. An emphasis has been placed on efficiency and simplicity.

Moonscript was chosen because GLua kind of sucks and Moonscript makes writing new addons tolerable. We provide auto-compiled code for you, so you can still run this without issue on your server.

## Dependencies
 - [CFC Logger](https://github.com/CFC-Servers/cfc_logger)

## Usage

**Simple:**
 - Snag a copy from the [Releases](https://github.com/CFC-Servers/cfc_77.15.580/releases) tab and put it in your addons directory.

**Version Controlled**
 - You can clone this repository directly into your addons directory, but be sure to checkout the `lua` branch which contains the latest compiled code (same as the lastest Release)

## Credit
 - Inspiration from https://github.com/HexaneNetworks/gmod-netlibrary-debug

## RCW 77.15.580
> **Unlawful use of net to take fish—Penalty.**
>  - (1) A person is guilty of unlawful use of a net to take fish in the second degree if the person:
>    - (a) Lays, sets, uses, or controls a net or other device or equipment capable of taking fish from the waters of this state, except if the person has a valid license for such fishing gear from the director under this title and is acting in accordance with all rules of the commission and director; or
>    - (b) Fails to return unauthorized fish to the water immediately while otherwise lawfully operating a net under a valid license.
>  - (2) A person is guilty of unlawful use of a net to take fish in the first degree if the person:
>    - (a) Commits the act described by subsection (1) of this section; and
>    - (b) The violation occurs within five years of entry of a prior conviction for a gross misdemeanor or felony under this title involving fish, other than a recreational fishing violation, or involving unlawful use of nets.
>  - (3)
>    - (a) Unlawful use of a net to take fish in the second degree is a gross misdemeanor. Upon conviction, the department shall revoke any license held under this title allowing commercial net fishing used in connection with the crime.
>    - (b) Unlawful use of a net to take fish in the first degree is a class C felony. Upon conviction, the department shall order a one-year suspension of all commercial fishing privileges requiring a license under this title.
>  - (4) Notwithstanding subsections (1) and (2) of this section, it is lawful to use a landing net to land fish otherwise legally hooked.
