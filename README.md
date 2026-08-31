# DHH FM

**Always broadcasting.**

DHH FM puts David Heinemeier Hansson's public X activity in the Omarchy Quattro bar: a compact feed, rolling 24-hour statistics, and a tiny animated station ident that lights up when the signal is busy.

> Early preview: the UI and source adapter foundation are in place. X developer access or a user-supplied RSS-compatible endpoint is required for live data.

## Features

- Animated circular DHH station ident with ON AIR and dead-air states.
- Feed filters for all transmissions, posts, and replies.
- Rolling 24-hour post and reply counts.
- Public engagement and view totals when the source supplies them.
- Open a transmission, launch X's reply composer, or copy its link.
- Ten-minute background refresh with a local seven-day cache.
- Honest stale, partial-history, and source-error states.
- No browser cookies, X password, or posting permission.

DHH FM reports public engagement—not estimated reach. True reach is private analytics and the plugin does not invent it.

## Install

```sh
omarchy plugin add https://github.com/lgse/dhh-fm.git --enable
```

If needed, add it to the bar explicitly:

```sh
omarchy bar plugin add lgse.dhh-fm --section right
```

## Tune the station

Configuration is stored with mode `0600` in:

```text
~/.config/omarchy/dhh-fm/config.json
```

### Official X API

Configure the source:

```sh
python3 ~/.config/omarchy/plugins/lgse.dhh-fm/dhh-fm.py configure x-api
```

Supply an app bearer token through the environment used to launch `omarchy-shell`:

```sh
export DHH_FM_X_BEARER_TOKEN='...'
```

For a quick local setup, `bearer_token` may instead be added to the private config file. The environment is preferred because it keeps the token out of configuration backups.

The adapter requests DHH's latest 100 public posts and public metrics through X API v2. Available endpoints, quotas, fields, and pricing are controlled by X and may vary by developer tier.

### RSS-compatible fallback

DHH FM can consume a user-provided RSS/Nitter-compatible feed:

```sh
python3 ~/.config/omarchy/plugins/lgse.dhh-fm/dhh-fm.py \
  configure rss --rss-url 'https://YOUR-INSTANCE/dhh/rss'
```

RSS is credential-free but usually lacks engagement metrics and complete reply context. Instances can also disappear or rate-limit requests; DHH FM deliberately does not ship a hard-coded public instance.

Middle-click the bar ident or use the panel refresh button after changing sources.

## State

Normalized public posts are cached at:

```text
~/.cache/omarchy/dhh-fm/feed.json
```

The cache keeps the panel useful during temporary network or provider failures. It contains only normalized public posts and public metrics.

## Interactions

- **Left-click:** open or close DHH FM.
- **Middle-click:** refresh the feed.
- **Transmission card:** open on X.
- **Reply:** open X's browser reply composer.
- **Copy:** copy the public post URL with `wl-copy`.

## Requirements

- Omarchy Quattro
- Python 3
- `wl-copy` from `wl-clipboard` for copy-link actions
- Either X API v2 access or a user-configured RSS-compatible endpoint

## Development

```sh
npm test
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml Service.qml DhhAvatar.qml
```

The helper can be exercised without loading the plugin:

```sh
python3 dhh-fm.py refresh | python3 -m json.tool
```

See [`docs/PRODUCT.md`](docs/PRODUCT.md) for product voice, data principles, and future ideas.

## Privacy and safety

Omarchy plugins run as unsandboxed code inside `omarchy-shell`; review third-party code before enabling it. DHH FM does not read browser profiles, browser cookies, or X session credentials. Replying is handed to the user's browser rather than performed by the plugin.

DHH FM is an unofficial, lighthearted public-feed reader. It is not affiliated with or endorsed by David Heinemeier Hansson, 37signals, Omarchy, or X Corp. Names and marks belong to their respective owners.

## License

[MIT](LICENSE)
