import importlib.util
import pathlib
import unittest

MODULE_PATH = pathlib.Path(__file__).parents[1] / "dhh-fm.py"
spec = importlib.util.spec_from_file_location("dhh_fm", MODULE_PATH)
dhh_fm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dhh_fm)


class HelperTests(unittest.TestCase):
    def test_classifies_x_references(self):
        self.assertEqual(dhh_fm.classify_references([]), "post")
        self.assertEqual(dhh_fm.classify_references([{"type": "replied_to"}]), "reply")
        self.assertEqual(dhh_fm.classify_references([{"type": "quoted"}]), "quote")
        self.assertEqual(dhh_fm.classify_references([{"type": "retweeted"}]), "repost")

    def test_calculates_rolling_stats(self):
        now = dhh_fm.parse_time("2026-03-18T12:00:00Z")
        posts = [
            {"kind": "post", "created_at": "2026-03-18T11:00:00Z", "metrics": {"likes": 5, "views": 100}},
            {"kind": "reply", "created_at": "2026-03-18T10:00:00Z", "metrics": {"likes": 2, "replies": 1}},
            {"kind": "post", "created_at": "2026-03-16T10:00:00Z", "metrics": {"likes": 99}},
        ]
        stats = dhh_fm.calculate_stats(posts, now=now)
        self.assertEqual(stats["total"], 2)
        self.assertEqual(stats["posts"], 1)
        self.assertEqual(stats["replies"], 1)
        self.assertEqual(stats["engagement"], 8)
        self.assertEqual(stats["views"], 100)

    def test_normalizes_x_tweet(self):
        tweet = {
            "id": "42",
            "text": "Ship it.",
            "created_at": "2026-03-18T11:00:00.000Z",
            "referenced_tweets": [{"type": "replied_to", "id": "40"}],
            "public_metrics": {"like_count": 7, "reply_count": 2, "impression_count": 90},
        }
        normalized = dhh_fm.normalize_x_tweet(tweet, {})
        self.assertEqual(normalized["kind"], "reply")
        self.assertEqual(normalized["url"], "https://x.com/dhh/status/42")
        self.assertEqual(normalized["metrics"]["views"], 90)


if __name__ == "__main__":
    unittest.main()
