import unittest

from app.groq_client import build_messages, extract_chat_text
from app.handbook import search_handbook


class GroqPromptTests(unittest.TestCase):
    def test_messages_include_only_the_supplied_chunks(self):
        messages = build_messages(
            "Can I sit the exam with 70 percent attendance?",
            [{"role": "user", "content": "What are the library hours?"}],
            "[ACP-001] Attendance\nAnswer: You need at least 80% attendance.",
        )
        self.assertEqual(messages[0]["role"], "system")
        self.assertIn("80% attendance", messages[0]["content"])
        self.assertNotIn("library hours", messages[0]["content"].lower())
        self.assertEqual(messages[-1]["content"], "Can I sit the exam with 70 percent attendance?")

    def test_attendance_search_returns_the_attendance_rule_only(self):
        matches = search_handbook("How much attendance do I need to sit the final exam?")
        self.assertGreaterEqual(len(matches), 1)
        self.assertLessEqual(len(matches), 3)
        self.assertEqual(matches[0]["id"], "ACP-001")
        self.assertIn("80%", matches[0]["answer"])

    def test_unrelated_question_loads_no_chunks(self):
        self.assertEqual(search_handbook("What is the weather in Lahore today?"), [])

    def test_extracts_chat_text_without_think_blocks(self):
        payload = {
            "choices": [
                {
                    "message": {
                        "content": "<think>draft</think> You need 75% attendance.",
                    }
                }
            ]
        }
        self.assertEqual(extract_chat_text(payload), "You need 75% attendance.")


if __name__ == "__main__":
    unittest.main()
