import unittest

from app.knowledge import linked_place_ids, place_id_for_text


class PlaceLinkTests(unittest.TestCase):
    def test_eating_question_links_the_cafe(self):
        self.assertEqual(linked_place_ids("where can I eat lunch?", []), ["cafe"])

    def test_unrelated_question_links_nothing(self):
        self.assertEqual(linked_place_ids("who won the cricket world cup?", []), [])

    def test_a_library_chunk_keeps_its_place_tag(self):
        self.assertEqual(place_id_for_text("The central library is open until 8 PM."), "library")
        self.assertEqual(
            linked_place_ids("when does the library open?", [{"place_id": "library", "q": "library hours"}]),
            ["library"],
        )


if __name__ == "__main__":
    unittest.main()
