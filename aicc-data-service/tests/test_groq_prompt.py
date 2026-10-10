import unittest

from app.groq_client import build_messages, extract_chat_text


class GroqPromptTests(unittest.TestCase):
    def test_messages_include_policy_history_and_question(self):
        messages = build_messages(
            "Can I sit the exam with 70 percent attendance?",
            [{"role": "user", "content": "What are the library hours?"}],
        )
        self.assertEqual(messages[0]["role"], "system")
        self.assertIn("75% attendance", messages[0]["content"])
        self.assertEqual(messages[1]["content"], "What are the library hours?")
        self.assertEqual(messages[-1]["content"], "Can I sit the exam with 70 percent attendance?")

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
