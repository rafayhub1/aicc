import unittest

from app.groq_client import build_messages, choose_reply, extract_chat_text
from app.handbook import load_entries, search_handbook


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
        self.assertEqual(matches[0]["id"], "ACP-01")
        self.assertIn("80%", matches[0]["answer"])

    def test_handbook_has_every_bilingual_answer(self):
        entries = load_entries()
        self.assertEqual(len(entries), 100)
        self.assertTrue(all(entry["ua"] and entry["ra"] for entry in entries))

    def test_urdu_question_returns_the_urdu_handbook_answer(self):
        matches = search_handbook("حاضری کتنی چاہیے؟")
        self.assertEqual(matches[0]["id"], "ACP-01")
        reply = choose_reply("حاضری کتنی چاہیے؟", "حاضری کتنی چاہیے؟", matches)
        self.assertIn("80", reply)
        self.assertNotIn("حاضری کتنی چاہیے", reply)

    def test_roman_urdu_question_returns_the_roman_answer(self):
        question = "hazri kitni chahiye?"
        matches = search_handbook(question)
        self.assertEqual(matches[0]["id"], "ACP-01")
        reply = choose_reply(question, question, matches)
        self.assertIn("80%", reply)
        self.assertNotEqual(reply.strip().lower(), question)

    def test_urdu_phone_penalty_is_not_a_generic_exam_rule(self):
        matches = search_handbook("امتحان میں موبائل کی سزا کیا ہے؟")
        self.assertEqual(matches[0]["id"], "EXM-10")
        self.assertIn("3,000", matches[0]["answer"])

    def test_unrelated_question_loads_no_chunks(self):
        self.assertEqual(search_handbook("What is the weather in Lahore today?"), [])
        self.assertEqual(search_handbook("آج لاہور میں موسم کیسا ہے؟"), [])

    def test_english_echo_falls_back_to_the_handbook_sentence(self):
        question = "How much attendance do I need?"
        matches = search_handbook(question)
        reply = choose_reply(question, question, matches)
        self.assertIn("80%", reply)

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
