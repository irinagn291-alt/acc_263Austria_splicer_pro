<!-- gf-brief source=2c96f22b2705d7116fcab00b9e4c93ef7fcb33e7d1c08060b18688ff6442ec48 written=2026-09-26T02:22:59+03:00 -->
# Splicer

## What it is

Splicer is a watch pile for one person on this device. You stash titles on a stack, draw one onto the gate, and burn it when that watch finishes so the pile shrinks. It is for people who want to finish one title at a time, not keep a growing seen shelf or open a store of streams.

## Launch and onboarding

A cold launch on a device that has never finished onboarding shows a short system launch screen, then a three-page cover. Each page has **Skip** at the top right. **Skip** ends onboarding and opens the board in the same way as finishing the last page.

1. Illustration, then **Keep one title on the gate.** and **Splicer is a watch pile for this device. You stash titles, then burn them one at a time.** Bottom control: **Next**.
2. Illustration, then **Draw, then burn.** and **Draw moves the top of the stack onto the gate. Burn writes the finish and takes that title off the board.** Bottom control: **Next**.
3. Illustration, then **Ash keeps the order.** and **Rate each burn from 1 to 5. Profile reads those grades and nothing else.** Bottom control: **Continue**.

After **Skip** or **Continue**, a first-time device with nothing saved shows the empty-board screen (**Nothing is on the board.**). On Simulator, the first launch can skip this cover and open the board already filled (see Starter content). Later launches return to the board as it was left. Killing the app mid-cover, without **Skip** or **Continue**, shows page 1 again.

## Screens

### Nothing is on the board

Shown when the stack is empty, the gate is empty, and there are no burns yet. There is no **Discover**, **Ash**, **Profile**, or **Settings** row on this screen.

- Headline: **Nothing is on the board.**
- Line: **Stash a title on the stack, then draw it onto the gate when you are ready to watch.**
- **Stash a title** opens **Discover**.

After the first stash, or after any burn exists, this full-page empty state does not return unless **Reset all data** clears the board.

### Board (Burn the gate)

Home is not a tab bar. A marquee sits above two side-by-side lanes: **Stack** (narrow) and **Gate** (wide). The four chrome controls open sheets and do not replace the board.

Marquee:

- Title: **Burn the gate**
- Line when a title is seated: **Watch {title}. Burn it when you finish.**
- Line when the stack is empty and the gate is open: **Stash a title, then draw it onto the gate.**
- Line when the stack has titles and the gate is open: **Draw the top of the stack onto the gate.**
- **Discover** opens the Discover sheet.
- **Ash** opens the Ash sheet.
- **Profile** opens the Profile sheet.
- **Settings** opens the Settings sheet.

If a save did not land, a banner can read **The last save did not land. The board on screen is still the one in memory.** If a saved board could not be read, it can read **The saved board could not be read. This session started empty.** Both offer **Read the board again**, which reloads the board.

**Stack** lane:

- Label **Stack** and a count of titles on the pile.
- Empty copy: **The stack is empty.**
- When titles exist, each title is listed. There is no control to delete one title.
- After a stash, draw, or burn, a short note can appear: **Stashed {title} on the stack.** / **{title} is on the gate. Burn it when the watch finishes.** / **The stack is bare. Stash a title before you draw.** / **The gate already holds a title. Burn it before you draw again.** / **Burned {title}. Rate the burn.** / **Draw a title onto the gate before you burn.** / **The board has nothing on the gate to burn.** / **The board is clear.**
- If a save failed, also: **The last save did not land. The pile on screen is still the one in memory.**
- **Stash** opens **Discover**.
- **Draw** moves the first title on the stack onto the gate. It stays disabled until the gate is **Open** and the stack has at least one title.

**Gate** lane:

- Label **Gate**.
- Chip **Open** when nothing is seated, or **Seated** when a title is on the gate.
- When seated: the title, decorative art, and **This is the title you are watching. Burn it when you finish.**
- When open: **No title is seated.** and **Draw the top of the stack onto the gate.**
- **Burn the gate** writes the finish, takes that title off the board, and opens the rate sheet. It stays disabled while the gate is **Open**. While the burn is in progress the control is disabled and shows a spinner.

After a successful burn, a medium sheet appears:

- **Rate {title}**
- **The grade stays on this burn.**
- Five controls labeled **1**, **2**, **3**, **4**, and **5**. Each writes that grade on this burn and dismisses the sheet.
- Dismissing the sheet without a number leaves the burn **Unrated**. There is no later control to change or add a grade.

### Discover

Sheet title: **Discover**. An X control closes it (VoiceOver: **Close discover**).

- Field placeholder **Search a title**. The keyboard offers **Done**, which dismisses the keyboard. Tapping outside the field also dismisses it.
- While a look-up is in flight long enough to show, **Searching titles** appears.
- An empty query lists the shelf on this device: **Night Ferry**, **Glass Orchard**, **Low Tide Ledger**, **Copper Hour**.
- Each row shows the title and **Stash on the stack**. Tapping stashes that title, closes Discover, and returns to the board.
- If nothing matches: **Nothing matched that search. The shelf on this device is listed below.** plus **Search again**, and the four shelf titles stay listed.
- If the look-up does not answer: **Search did not answer. The shelf on this device is still here.** plus **Search again**, and the four shelf titles stay listed.
- **Search again** is disabled while a search is in progress.
- If the list is empty: **No titles to stash.** / **The shelf on this device is still here when the search is clear.** / **Show the shelf** (clears the field and shows the shelf).
- Always at the bottom: **Title names from Open Food Facts**, a tappable credit. Matching names from that source appear as titles to stash. The rows show the name only.

### Ash

Sheet title: **Ash**. An X control closes it (VoiceOver: **Close ash**).

Empty:

- **No burns yet.**
- **Finish the title on the gate and burn it. Ash keeps that order on this device.**
- Panel **Burn order** / **Each finish is written once, then the gate clears. The stack is not listed here.**
- **Return to the gate** closes the sheet.

Populated: a list in burn order. Each row is the title, an eight-digit day figure for that finish, and either **Grade {n}** or **Unrated**. Rows are not tappable. The stack is not listed.

If a save failed: **A save failed. Ash is showing the burns still held in memory.** and **Read the board again**.

### Profile

Sheet title: **Profile**. An X control closes it (VoiceOver: **Close profile**). Profile does not list the stack.

Empty:

- **No grades yet.**
- **Burn the gate, then rate it. Profile only reads those marks.**
- Panel **What a grade is** / **A grade is a whole number from 1 to 5, written on the burn and kept on this device.**
- **Return to the gate** closes the sheet.

Populated:

- **Burns** and a count of every burn (including **Unrated**).
- **Grades stay on the burn. The stack is not part of this count.**
- Rows **Grade 1** through **Grade 5**, each with how many burns have that grade.

If a save failed and burns are still in memory: **A save failed. These counts are the burns still held in memory.** and **Read the board again**.

If a save failed and there is nothing to count: **Profile could not read a saved chart.** / **The last write failed and there is no burn count to show.** / **Read the board again**.

### Settings

Sheet title: **Settings**. An X control closes it (VoiceOver: **Close settings**).

- **Run onboarding again** closes Settings and shows the three-page cover again. The stack, gate, and burns stay. **Skip** or **Continue** returns to the board.
- **Reset all data**, with footer **Reset removes the stack, the gate, and every burn on this device.**
- Confirm alert **Reset the board?** / **The stack, the gate, and every burn mark will leave this device.** Buttons: **Reset all data** (destroys the board and returns through onboarding) and **Cancel**.
- **Contact** opens the support page.

## Features

- A watch pile on this device: stash titles, keep one on the gate, burn it when the watch finishes.
- **Discover**: search a title or pick from the shelf, then **Stash on the stack**.
- **Draw**: move the top of the stack onto the gate. Only one title can be seated.
- **Burn the gate**: write the finish, take that title off the board, then rate 1 to 5.
- **Ash**: burn order with day and grade or **Unrated**. Not a list of titles still on the board.
- **Profile**: burn count and how many burns hold each grade from 1 to 5.
- **Settings**: run onboarding again, reset all data (confirmed), **Contact**.
- Board, ash, and profile stay on this device across launches until reset.

## Behaviours that can look like bugs

- After onboarding on a fresh device, **Discover**, **Ash**, **Profile**, and **Settings** are missing. The only control is **Stash a title**. One stash (or any later burn) brings the full board chrome back.
- **Draw** does nothing while disabled. It waits until the gate chip reads **Open** and **Stack** is not **The stack is empty.** If draw is refused, the stack note can read **The stack is bare. Stash a title before you draw.** or **The gate already holds a title. Burn it before you draw again.**
- **Burn the gate** stays disabled while the chip reads **Open**. The note can read **Draw a title onto the gate before you burn.**
- Only one title sits on the gate. A second **Draw** is refused until that title is burned.
- There is no control to remove one stack title. The way off the pile is **Draw** then **Burn the gate**, or **Reset all data**.
- The rate sheet can be dismissed without **1**–**5**. That burn stays **Unrated** in **Ash**. **Profile** still counts it under **Burns**, so the five **Grade** rows can add up to less than **Burns**. There is no later rate control.
- **Ash** and **Profile** stay empty until the first burn: **No burns yet.** and **No grades yet.** **Return to the gate**, then finish a seated title.
- Clearing **Search a title** (or a failed / empty look-up) always shows the same four shelf titles. That is the shelf, not a stuck result. **Search again** retries the current words.
- **Search again** is disabled while **Searching titles** is showing.
- **Skip** on any onboarding page jumps to the board. That is the same end as **Continue** on page 3.
- **Run onboarding again** loops back through the cover on purpose. The pile is still there afterward.
- **Reset all data** after the alert clears the pile and shows onboarding again, then **Nothing is on the board.**
- After the last seated title is burned and the stack is empty, the board stays up (**Open**, **No title is seated.**) instead of **Nothing is on the board.** because burns now exist. Stash or draw the next title as usual.
- Save-failed banners and **Read the board again** mean the last write did not land or a saved board could not be read. The lanes on screen are still the live pile; the button reloads them.
- The stack list grows with every stash, including the same title more than once. **Ash** grows with every burn. Only **Reset all data** clears both.

## Starter content and resume

Discover’s shelf, shown when **Search a title** is clear, is always **Night Ferry**, **Glass Orchard**, **Low Tide Ledger**, and **Copper Hour**.

On Simulator, the first launch can finish onboarding for you, stash those four titles, and draw **Night Ferry** onto the gate so **Burn the gate** is already enabled and three titles remain on the stack. A physical device does not get that filled board.

The stack, the seated gate title, burns, and grades resume after quit. An unfinished onboarding cover does not resume mid-page. An unrated burn stays **Unrated**.

## Permissions

None.

## Absent

Login or accounts, in-app purchase, ads, analytics, user-generated content, account deletion flow, and the App Tracking Transparency prompt are all absent.

## Data and support

The pile, burns, and grades stay on this device. **Contact** in **Settings** opens the support page.

## Scanning and health

None. There is no barcode or QR scan. The app does not show health, medical, or product-health information. **Discover** lists names only. The on-screen credit is **Title names from Open Food Facts**.

## Platform

English copy only; no other languages are bundled. There is no region lock. Day figures on **Ash** use the device calendar. Counts and grades follow the device number format without grouping separators. Portrait only, on iPhone and iPad. The interface is dark and does not follow a light appearance. Minimum iOS version is 17.0.

## Category

Entertainment.
