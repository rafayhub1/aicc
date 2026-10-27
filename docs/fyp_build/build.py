"""Build the AICC final-year Word report."""

import os
import sys

from docx.enum.section import WD_SECTION

sys.path.insert(0, os.path.dirname(__file__))

from chapters_1_3 import add_chapter_1, add_chapter_2, add_chapter_3
from chapters_4_5 import add_chapter_4, add_chapter_5
from chapters_6 import add_chapter_6
from chapters_7_9 import add_chapter_7, add_chapter_8, add_chapter_9, add_references
from diagrams import build_all
from front import add_front
from styles import configure_section, enable_update_fields, new_document


def main():
    figures = build_all()
    document = new_document()
    add_front(document)
    body_section = document.add_section(WD_SECTION.NEW_PAGE)
    configure_section(body_section, start=1, fmt="decimal")
    add_chapter_1(document)
    add_chapter_2(document)
    add_chapter_3(document)
    add_chapter_4(document)
    add_chapter_5(document)
    add_chapter_6(document, figures)
    add_chapter_7(document)
    add_chapter_8(document)
    add_chapter_9(document)
    add_references(document)
    enable_update_fields(document)
    output = r"e:\FYP\docs\AICC_FYP_Final_Documentation.docx"
    os.makedirs(os.path.dirname(output), exist_ok=True)
    document.save(output)
    print(output)


if __name__ == "__main__":
    main()
