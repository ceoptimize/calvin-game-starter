# Hosting and selling your games

This is how to put a finished game where people can play it and pay for it. It covers browser games (HTML and JavaScript, with or without a Python server) and, later, Unity builds. The business side (the company, taxes, the bank account) is Mom's, and the parts that need her are marked.

## The short version

1. Your games live on **itch.io**. It hosts browser games and downloads, runs the store page, takes the money, and pays out.
2. The store account belongs to Mom's company. You publish through it.
3. Your first games are **free** or **pay what you want**. Charge a fixed price once a game has a real store page and some players.
4. If a game is multiplayer, the **server** lives on its own small host, not on itch and not on any other computer in the house.
5. Never collect personal information from players. Most of them will be under 13, and that has legal rules.
6. **Steam** is for later, when a Unity game is ready.

## Where the game lives: itch.io

itch.io is the main store for independent games. You upload a game, it makes a page for it, and people play or download it from there.

**A browser game** is uploaded as a ZIP file. Rules from itch's own docs:

- The ZIP must contain a file called `index.html` at the top level. That is the file people see when they play.
- No more than 1,000 files inside the ZIP, no more than 500 MB unpacked, and no single file over 200 MB.
- You choose how it shows: **Embed in page** (you set the width and height, the game runs in the page) or **Click to launch in fullscreen**.
- Anything your game loads from somewhere else, or any server it talks to, must use HTTPS. For a multiplayer game that means the server address starts with `wss://`, not `ws://`.

**A Unity game** can be uploaded two ways: a WebGL build as a ZIP so it plays in the browser, or a Windows build as a ZIP that people download. On the project page there is a SharedArrayBuffer checkbox; Unity WebGL builds usually need it turned on.

**A Python game** (pygame) cannot run in a browser. Package it as a Windows download, or better, keep Python for the server and make the client a browser game.

## The store account (Mom)

itch's terms say users must be over 13, and anyone who publishes and gets paid must be over 18 or have a parent's legal consent. So the seller account is set up once under Mom's company as a studio page, and you publish games on it.

One-time setup for Mom:

1. Create the account and a studio page in the company's name.
2. In seller settings, pick the payout mode **Collected by itch.io, paid later**. itch collects the money, handles sales tax and VAT, and pays out when you ask.
3. Complete the tax interview once (the company's tax information). Without it, itch cannot pay out.
4. Set the revenue share. itch defaults to keeping 10% of each sale, and you can change that number. Payment processor fees come off on top of that.

itch pays out when you request it, once the balance is above a small minimum. Sales sit in the account until then.

## What to charge

- **First games: free or pay what you want.** Your first players are people you tell about the game. Pay what you want lets them support you without you having to defend a price.
- **Fixed price later.** When a game has a store page with screenshots, a short video or GIF, a controls list, and a few reviews, a fixed price makes sense. Look at what similar games on itch charge.
- **A good store page** has: three or more screenshots, one short GIF or video of actual play, a two-sentence description, the controls, and a note saying whether it is single player or multiplayer and how to join a friend.

## Hosting the multiplayer server

itch hosts only the part players download to their browser. If a game has a Python server (the part that keeps everyone's positions and scores in sync), that server needs its own host that is always on and reachable from the internet.

Rules for the server:

- It must answer on a secure address (`wss://`). The hosts below give you that for free on their own domain. A plain `ws://` server will be blocked by the browser because the itch page is HTTPS.
- It gets its own host. Do not run it on Mom's other server or on a home computer. A public game server is the thing on any network most likely to get poked at, and it should sit by itself.
- Use room codes to join, not accounts. The server keeps a room alive while people are in it and forgets it after.

Hosts that fit, with prices as of this writing:

| Host | Cost | Notes |
|---|---|---|
| Railway | $5 per month Hobby plan, includes $5 of usage | Simplest deploy from a Git repo, secure address included |
| Render | Free tier, or $7 per month Starter | The free tier goes to sleep after 15 minutes idle, so the first player waits while it wakes up |
| Fly.io | About $2 to $5 per month for one small always-on machine | Usage billed, no free tier anymore |

For a first multiplayer game, Railway is the right pick: push the server folder, get a `wss://` address, paste that address into the client. The account is Mom's, since it takes a payment card.

## Player privacy (this one matters)

Your players will mostly be kids under 13. In the United States, a law called COPPA says a game that collects **personal information** from children under 13 needs verifiable parental consent first, and that is a burden you do not want. The fix is simple: do not collect any.

Personal information under COPPA includes a first and last name, a home address, an email address or any other way to contact someone online, a screen name that works as a way to contact someone, a phone number, a photo, video, or audio of a child, location down to the street or town, and a persistent identifier that can recognize a user over time and across different sites.

What that means for your games:

- **No accounts, no sign-ups, no email addresses, no real names.**
- **No free-text chat.** Preset phrases ("nice!", "gg", "go left") are fine. A text box where kids type anything is not.
- **A nickname is fine** as long as it cannot be used to contact the player. A leaderboard with chosen nicknames and scores is fine.
- **No photos, no microphone, no location.**
- **No third-party ad or analytics code you added yourself** that tracks players across sites. itch's own page and the portals below handle their own ads under their own rules; you do not add tracking on top.

Follow those five rules and COPPA does not apply to your game.

## Another way to earn: portals with ads

Some sites host free browser games and share the ad money with the maker. This can pay more than selling a small browser game, and a game can be on a portal and on itch at the same time.

- **CrazyGames**: upload an HTML5 or Unity WebGL build through their developer portal, their team reviews it, and it goes live. No fee, no exclusivity. You earn a share of the ads their SDK shows. They pay out monthly once the balance passes a minimum. The account is Mom's.
- **Poki**: they require desktop and mobile support and an initial download under 8 MB. If a player comes to your game directly (a link you shared), you keep all of that revenue; if they come through Poki's site, it is split 50/50.

Both need you to add their SDK to the game (a small piece of code that shows ads at the right moments). Both have a quality bar, so this is for a game that is already polished.

## Steam (later, for a Unity game)

Steam is where Windows games sell best, and it is a bigger step. Publishing through Steam Direct costs $100 per game, refunded once that game has earned $1,000. It needs the company's tax documents, verified bank details, and identity information, so it is Mom's account. Steam is not for browser games.

## Before you publish anything

- Play it in a fresh browser window with no extensions, start to finish, with no errors in the browser console.
- The controls are written on the store page.
- Every piece of art and sound you did not make yourself is listed in `Game/Assets/Art/CREDITS.md` (or the equivalent file for a browser game) with its license, and the license allows selling.
- For a multiplayer game: two people on two different networks can join the same room.
- Mom has read the store page.

## Sources

- itch.io HTML5 upload rules: https://itch.io/docs/creators/html5
- itch.io terms (ages, publishers): https://itch.io/docs/legal/terms
- itch.io seller payouts and the tax interview: https://itch.io/updates/updates-to-itchio-seller-accounts-payouts-tax-interview
- FTC COPPA questions and answers: https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions
- Steam Direct fee: https://partner.steamgames.com/doc/gettingstarted/appfee
- CrazyGames developer portal: https://developer.crazygames.com/
- Poki requirements: https://sdk.poki.com/requirements
