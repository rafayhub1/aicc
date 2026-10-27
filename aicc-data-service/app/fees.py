"""Published fee lines used to draw a challan. Totals are checked when this module loads."""

from typing import TypedDict


class FeeLine(TypedDict):
    label: str
    amount: int


PUBLISHED_TOTALS: dict[str, int] = {
    "BSPSY": 120_000,
    "BSCS": 150_000,
    "BBA": 100_000,
}

FEE_STRUCTURE: dict[str, list[FeeLine]] = {
    "BSPSY": [
        {"label": "Tuition", "amount": 95_000},
        {"label": "Examination", "amount": 8_000},
        {"label": "Laboratory", "amount": 7_000},
        {"label": "Library and IT", "amount": 6_000},
        {"label": "Student activity", "amount": 4_000},
    ],
    "BSCS": [
        {"label": "Tuition", "amount": 115_000},
        {"label": "Examination", "amount": 8_000},
        {"label": "Laboratory", "amount": 15_000},
        {"label": "Library and IT", "amount": 8_000},
        {"label": "Student activity", "amount": 4_000},
    ],
    "BBA": [
        {"label": "Tuition", "amount": 78_000},
        {"label": "Examination", "amount": 8_000},
        {"label": "Laboratory", "amount": 4_000},
        {"label": "Library and IT", "amount": 6_000},
        {"label": "Student activity", "amount": 4_000},
    ],
}

_BELOW_TWENTY = [
    "Zero",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
    "Ten",
    "Eleven",
    "Twelve",
    "Thirteen",
    "Fourteen",
    "Fifteen",
    "Sixteen",
    "Seventeen",
    "Eighteen",
    "Nineteen",
]
_TENS = [
    "",
    "",
    "Twenty",
    "Thirty",
    "Forty",
    "Fifty",
    "Sixty",
    "Seventy",
    "Eighty",
    "Ninety",
]


def _words(value: int) -> str:
    if value < 20:
        return _BELOW_TWENTY[value]
    if value < 100:
        tens, rest = divmod(value, 10)
        return _TENS[tens] if rest == 0 else f"{_TENS[tens]} {_words(rest)}"
    if value < 1000:
        hundreds, rest = divmod(value, 100)
        head = f"{_words(hundreds)} Hundred"
        return head if rest == 0 else f"{head} {_words(rest)}"
    if value < 1_000_000:
        thousands, rest = divmod(value, 1000)
        head = f"{_words(thousands)} Thousand"
        return head if rest == 0 else f"{head} {_words(rest)}"
    raise ValueError(f"Amount {value} is outside the supported range")


def fee_lines(department: str) -> list[FeeLine]:
    try:
        return FEE_STRUCTURE[department]
    except KeyError as exc:
        raise ValueError(f"No fee structure for department {department}") from exc


def fee_total(department: str) -> int:
    return sum(line["amount"] for line in fee_lines(department))


def amount_in_words(total: int) -> str:
    return f"{_words(total)} Rupees Only"


def _assert_published_totals() -> None:
    for code, expected in PUBLISHED_TOTALS.items():
        actual = sum(line["amount"] for line in FEE_STRUCTURE[code])
        if actual != expected:
            raise AssertionError(
                f"{code} fee lines sum to {actual}, published total is {expected}"
            )


_assert_published_totals()
