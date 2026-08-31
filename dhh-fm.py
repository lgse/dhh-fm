#!/usr/bin/env python3
"""Fetch and normalize the public DHH feed for the DHH FM shell plugin."""

from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import html
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

USERNAME = "dhh"
USER_AGENT = "DHH-FM/0.1 (+https://github.com/lgse/dhh-fm)"
CONFIG_DIR = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config")) / "omarchy" / "dhh-fm"
CACHE_DIR = pathlib.Path(os.environ.get("XDG_CACHE_HOME", pathlib.Path.home() / ".cache")) / "omarchy" / "dhh-fm"
STATE_DIR = pathlib.Path(os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local" / "state")) / "omarchy" / "dhh-fm"
CONFIG_PATH = CONFIG_DIR / "config.json"
CACHE_PATH = CACHE_DIR / "feed.json"
STATE_PATH = STATE_DIR / "state.json"
TAG_RE = re.compile(r"<[^>]+>")
SPACE_RE = re.compile(r"\s+")


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def isoformat(value: dt.datetime) -> str:
    return value.astimezone(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def parse_time(value: str) -> dt.datetime:
    text = str(value or "").strip()
    if not text:
        raise ValueError("missing timestamp")
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def read_json(path: pathlib.Path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError, TypeError):
        return default


def write_json_private(path: pathlib.Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")
    os.chmod(temporary, 0o600)
    temporary.replace(path)


def load_config() -> dict:
    config = read_json(CONFIG_PATH, {})
    return config if isinstance(config, dict) else {}


def request_json(url: str, bearer_token: str) -> dict:
    request = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {bearer_token}", "User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def request_text(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read().decode("utf-8", errors="replace")


def classify_references(references: list[dict]) -> str:
    kinds = {str(reference.get("type", "")) for reference in references or []}
    if "replied_to" in kinds:
        return "reply"
    if "quoted" in kinds:
        return "quote"
    if "retweeted" in kinds:
        return "repost"
    return "post"


def public_metrics(raw: dict) -> dict:
    raw = raw or {}
    return {
        "likes": int(raw.get("like_count", 0) or 0),
        "replies": int(raw.get("reply_count", 0) or 0),
        "reposts": int(raw.get("retweet_count", 0) or 0),
        "quotes": int(raw.get("quote_count", 0) or 0),
        "views": int(raw.get("impression_count", 0) or 0),
    }


def normalize_x_tweet(tweet: dict, included_tweets: dict) -> dict:
    references = tweet.get("referenced_tweets") or []
    reply_reference = next((item for item in references if item.get("type") == "replied_to"), None)
    context = included_tweets.get(str(reply_reference.get("id"))) if reply_reference else None
    tweet_id = str(tweet.get("id", ""))
    return {
        "id": tweet_id,
        "text": str(tweet.get("text", "")).strip(),
        "created_at": str(tweet.get("created_at", "")),
        "kind": classify_references(references),
        "url": f"https://x.com/{USERNAME}/status/{tweet_id}",
        "reply_to_text": str((context or {}).get("text", "")).strip(),
        "metrics": public_metrics(tweet.get("public_metrics") or {}),
    }


def fetch_x_api(config: dict) -> list[dict]:
    token = os.environ.get("DHH_FM_X_BEARER_TOKEN") or str(config.get("bearer_token", ""))
    if not token:
        raise RuntimeError("X API source needs DHH_FM_X_BEARER_TOKEN or bearer_token in config.json")

    api_base = str(config.get("api_base", "https://api.x.com/2")).rstrip("/")
    user_url = f"{api_base}/users/by/username/{USERNAME}"
    user_payload = request_json(user_url, token)
    user_id = str((user_payload.get("data") or {}).get("id", ""))
    if not user_id:
        raise RuntimeError("X API did not return the @dhh user id")

    params = {
        "max_results": "100",
        "tweet.fields": "created_at,public_metrics,referenced_tweets",
        "expansions": "referenced_tweets.id",
    }
    url = f"{api_base}/users/{user_id}/tweets?{urllib.parse.urlencode(params)}"
    payload = request_json(url, token)
    included = {str(item.get("id")): item for item in (payload.get("includes") or {}).get("tweets", [])}
    return [normalize_x_tweet(tweet, included) for tweet in payload.get("data", [])]


def clean_html(value: str) -> str:
    return SPACE_RE.sub(" ", html.unescape(TAG_RE.sub(" ", value or ""))).strip()


def child_text(item: ET.Element, name: str) -> str:
    child = item.find(name)
    return "" if child is None or child.text is None else child.text.strip()


def rss_time(value: str) -> str:
    parsed = email.utils.parsedate_to_datetime(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return isoformat(parsed)


def classify_rss(title: str, description: str) -> str:
    combined = f"{title} {description}".lstrip().lower()
    if combined.startswith(("r to @", "replying to @")):
        return "reply"
    if combined.startswith(("rt by @", "reposted by @", "rt @")):
        return "repost"
    if "quoted tweet" in combined:
        return "quote"
    return "post"


def fetch_rss(config: dict) -> list[dict]:
    url = str(config.get("rss_url", "")).strip()
    if not url.startswith(("https://", "http://")):
        raise RuntimeError("RSS source needs an http(s) rss_url in config.json")
    root = ET.fromstring(request_text(url))
    posts = []
    for item in root.findall(".//item"):
        title = clean_html(child_text(item, "title"))
        description = clean_html(child_text(item, "description"))
        link = child_text(item, "link")
        guid = child_text(item, "guid") or link
        created_at = rss_time(child_text(item, "pubDate"))
        posts.append({
            "id": guid.rsplit("/", 1)[-1],
            "text": description or title,
            "created_at": created_at,
            "kind": classify_rss(title, description),
            "url": link,
            "reply_to_text": "",
            "metrics": {"likes": 0, "replies": 0, "reposts": 0, "quotes": 0, "views": 0},
        })
    return posts


def demo_posts() -> list[dict]:
    now = utc_now()
    samples = [
        (6, "reply", "Demo reply: context from the original conversation appears below the transmission."),
        (38, "post", "Demo transmission: DHH's latest public post will appear here when the station is tuned."),
        (95, "quote", "Demo quote: public engagement counters are shown when the source provides them."),
        (210, "post", "Demo transmission: open, reply, or copy a link directly from this card."),
    ]
    posts = []
    for index, (minutes, kind, text) in enumerate(samples, start=1):
        posts.append({
            "id": f"demo-{index}", "text": text,
            "created_at": isoformat(now - dt.timedelta(minutes=minutes)), "kind": kind,
            "url": "https://x.com/dhh", "reply_to_text": "Demo conversation context" if kind == "reply" else "",
            "metrics": {"likes": 37 * index, "replies": 3 * index, "reposts": 5 * index,
                        "quotes": index, "views": 3700 * index},
        })
    return posts


def merge_posts(fresh: list[dict], cached: list[dict], keep_days: int = 7) -> list[dict]:
    by_id = {str(post.get("id")): post for post in cached if post.get("id")}
    by_id.update({str(post.get("id")): post for post in fresh if post.get("id")})
    cutoff = utc_now() - dt.timedelta(days=keep_days)
    rows = []
    for post in by_id.values():
        try:
            if parse_time(post.get("created_at", "")) >= cutoff:
                rows.append(post)
        except (TypeError, ValueError):
            continue
    return sorted(rows, key=lambda post: post["created_at"], reverse=True)


def calculate_stats(posts: list[dict], now: dt.datetime | None = None) -> dict:
    now = now or utc_now()
    cutoff = now - dt.timedelta(hours=24)
    recent = []
    for post in posts:
        try:
            if cutoff <= parse_time(post.get("created_at", "")) <= now + dt.timedelta(minutes=5):
                recent.append(post)
        except (TypeError, ValueError):
            continue
    result = {"total": len(recent), "posts": 0, "replies": 0, "quotes": 0, "reposts": 0,
              "engagement": 0, "views": 0}
    for post in recent:
        kind = post.get("kind", "post")
        result[kind + "s" if kind != "reply" else "replies"] = result.get(
            kind + "s" if kind != "reply" else "replies", 0
        ) + 1
        metrics = post.get("metrics") or {}
        result["engagement"] += sum(int(metrics.get(key, 0) or 0) for key in ("likes", "replies", "reposts", "quotes"))
        result["views"] += int(metrics.get("views", 0) or 0)
    return result


def calculate_unread(posts: list[dict], seen_at: str = "") -> int:
    try:
        boundary = parse_time(seen_at) if seen_at else None
    except (TypeError, ValueError):
        boundary = None
    count = 0
    for post in posts:
        try:
            if boundary is None or parse_time(post.get("created_at", "")) > boundary:
                count += 1
        except (TypeError, ValueError):
            continue
    return count


def seen_at() -> str:
    state = read_json(STATE_PATH, {})
    return str(state.get("seen_at", "")) if isinstance(state, dict) else ""


def empty_snapshot(message: str = "Connect with a valid X API bearer token to unlock DHH FM") -> dict:
    return {
        "username": USERNAME,
        "source": "unconfigured",
        "fetched_at": "",
        "last_created_at": "",
        "partial_history": True,
        "connected": False,
        "error": message,
        "unread_count": 0,
        "stats": calculate_stats([]),
        "posts": [],
    }


def build_snapshot(posts: list[dict], source: str, error: str = "") -> dict:
    return {
        "username": USERNAME,
        "source": source,
        "fetched_at": isoformat(utc_now()),
        "last_created_at": posts[0]["created_at"] if posts else "",
        "partial_history": source != "demo",
        "connected": source in ("x-api", "rss"),
        "error": error,
        "unread_count": calculate_unread(posts, seen_at()),
        "stats": calculate_stats(posts),
        "posts": posts,
    }


def refresh() -> dict:
    config = load_config()
    source = str(config.get("source", "")).strip()
    cached = read_json(CACHE_PATH, empty_snapshot())
    cached_posts = cached.get("posts", []) if isinstance(cached, dict) else []
    if source not in ("x-api", "rss", "demo"):
        return cached if cached_posts else empty_snapshot()
    try:
        if source == "demo":
            fresh = demo_posts()
        else:
            fresh = fetch_x_api(config) if source == "x-api" else fetch_rss(config)
        snapshot = build_snapshot(merge_posts(fresh, cached_posts), source)
        write_json_private(CACHE_PATH, snapshot)
        return snapshot
    except (OSError, ValueError, RuntimeError, ET.ParseError, urllib.error.URLError) as error:
        if cached_posts and cached.get("connected"):
            cached["error"] = str(error)
            if isinstance(error, urllib.error.HTTPError) and error.code in (401, 403):
                cached["connected"] = False
            cached["unread_count"] = calculate_unread(cached_posts, seen_at())
            cached["stats"] = calculate_stats(cached_posts)
            return cached
        return empty_snapshot(str(error))


def mark_seen() -> dict:
    cached = read_json(CACHE_PATH, empty_snapshot())
    latest = str(cached.get("last_created_at", "")) if isinstance(cached, dict) else ""
    if latest:
        write_json_private(STATE_PATH, {"seen_at": latest})
    if isinstance(cached, dict):
        cached["unread_count"] = 0
    return cached


def save_configuration(source: str, bearer_token: str = "", rss_url: str = "") -> dict:
    if source not in ("x-api", "rss", "demo"):
        raise ValueError("unsupported source")
    config = load_config()
    config["source"] = source
    if bearer_token:
        config["bearer_token"] = bearer_token.strip()
    if rss_url:
        config["rss_url"] = rss_url.strip()
    write_json_private(CONFIG_PATH, config)
    return {"source": source, "configured": True}


def configure(args) -> dict:
    return save_configuration(args.source, rss_url=args.rss_url)


def configure_json() -> dict:
    try:
        payload = json.load(sys.stdin)
    except (ValueError, TypeError) as error:
        raise ValueError("invalid configuration payload") from error
    if not isinstance(payload, dict):
        raise ValueError("configuration payload must be an object")

    source = str(payload.get("source", ""))
    token = str(payload.get("bearer_token", "")).strip()
    rss_url = str(payload.get("rss_url", "")).strip()
    candidate = load_config()
    candidate["source"] = source
    if token:
        candidate["bearer_token"] = token
    if rss_url:
        candidate["rss_url"] = rss_url

    if source == "x-api":
        if not (os.environ.get("DHH_FM_X_BEARER_TOKEN") or candidate.get("bearer_token")):
            raise ValueError("Paste the Bearer Token from your X developer app")
        fresh = fetch_x_api(candidate)
    elif source == "rss":
        fresh = fetch_rss(candidate)
    else:
        raise ValueError("A live connection is required")

    save_configuration(source, bearer_token=token, rss_url=rss_url)
    cached = read_json(CACHE_PATH, empty_snapshot())
    cached_posts = cached.get("posts", []) if cached.get("source") == source else []
    snapshot = build_snapshot(merge_posts(fresh, cached_posts), source)
    write_json_private(CACHE_PATH, snapshot)
    return snapshot


def main() -> int:
    parser = argparse.ArgumentParser(description="DHH FM feed helper")
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("refresh", help="fetch and print the normalized snapshot")
    subparsers.add_parser("snapshot", help="print the cached snapshot")
    subparsers.add_parser("mark-seen", help="mark the latest cached transmission as seen")
    subparsers.add_parser("configure-json", help="read source configuration as JSON from stdin")
    config_parser = subparsers.add_parser("configure", help="configure a feed source")
    config_parser.add_argument("source", choices=("x-api", "rss", "demo"))
    config_parser.add_argument("--rss-url", default="")
    args = parser.parse_args()

    if args.command == "configure":
        result = configure(args)
    elif args.command == "configure-json":
        result = configure_json()
    elif args.command == "mark-seen":
        result = mark_seen()
    elif args.command == "snapshot":
        result = read_json(CACHE_PATH, empty_snapshot())
    else:
        result = refresh()
    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
