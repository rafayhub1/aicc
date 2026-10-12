import unittest

from app.groq_client import build_messages, choose_reply, extract_chat_text
from app.handbook import load_entries, plan_reply, search_handbook


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
        self.assertEqual(len(matches), 1)
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

    def test_generic_question_asks_what_they_mean(self):
        plan = plan_reply("kya rules hain")
        self.assertEqual(plan["kind"], "clarify")
        self.assertEqual(plan["entries"], [])

    def test_reworded_attendance_question_still_finds_the_rule(self):
        plan = plan_reply("Is 70 percent attendance enough to sit the final exam?")
        self.assertEqual(plan["kind"], "answer")
        self.assertEqual(plan["entries"][0]["id"], "ACP-01")
        self.assertIn("80%", plan["entries"][0]["answer"])

    def test_urdu_script_rewording_finds_the_attendance_rule(self):
        plan = plan_reply("فائنل امتحان کے لیے کتنی حاضری چاہیے؟")
        self.assertEqual(plan["kind"], "answer")
        self.assertEqual(plan["entries"][0]["id"], "ACP-01")

    def test_unclear_paraphrase_asks_instead_of_guessing(self):
        plan = plan_reply("Can I skip classes and still sit the final?")
        self.assertEqual(plan["kind"], "clarify")
        self.assertGreaterEqual(len(plan["entries"]), 2)

    def test_library_hours_paraphrase_hits_the_timings_rule(self):
        plan = plan_reply("library kab khulti hai")
        self.assertEqual(plan["kind"], "answer")
        self.assertEqual(plan["entries"][0]["id"], "FAC-02")
        self.assertIn("Monday to Sunday", plan["entries"][0]["answer"])

    def test_broad_scholarship_question_is_not_one_random_scheme(self):
        plan = plan_reply("scholarship kaise milegi")
        if plan["kind"] == "answer":
            self.assertIn("Six kinds", plan["entries"][0]["answer"])
        else:
            self.assertEqual(plan["kind"], "clarify")
            self.assertGreaterEqual(len(plan["entries"]), 2)

    def test_unrelated_question_loads_no_chunks(self):
        self.assertEqual(search_handbook("What is the weather in Lahore today?"), [])
        self.assertEqual(search_handbook("آج لاہور میں موسم کیسا ہے؟"), [])

    def test_model_elaboration_is_replaced_by_the_handbook_line(self):
        question = "How much attendance do I need?"
        matches = search_handbook(question)
        reply = choose_reply(
            question,
            "You need 80% attendance, the library is open all week, and you may freeze three semesters.",
            matches,
        )
        self.assertEqual(reply, matches[0]["answer"])

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
