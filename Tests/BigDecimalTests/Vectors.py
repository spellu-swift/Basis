# BigDecimalTests の期待値（Units/Vectors.swift）を生成する。
# 期待値は Python の decimal（General Decimal Arithmetic 仕様の実装）で計算する。
from decimal import (
    Context, Decimal, Inexact,
    ROUND_CEILING, ROUND_DOWN, ROUND_FLOOR,
    ROUND_HALF_DOWN, ROUND_HALF_EVEN, ROUND_HALF_UP, ROUND_UP,
)
from fractions import Fraction

RULES = [
    ("towardZero", ROUND_DOWN),
    ("awayFromZero", ROUND_UP),
    ("up", ROUND_CEILING),
    ("down", ROUND_FLOOR),
    ("toNearestOrEven", ROUND_HALF_EVEN),
    ("toNearestOrAwayFromZero", ROUND_HALF_UP),
    ("toNearestOrTowardZero", ROUND_HALF_DOWN),
]


def context(prec=5000, rounding=ROUND_HALF_EVEN, traps=()):
    return Context(prec=prec, rounding=rounding, Emax=10**9, Emin=-10**9, traps=list(traps))


EXACT = context()

# 2 項演算に使う値
PAIR_VALUES = [
    "0", "0.00", "1", "-1", "1.50", "-2.5", "123.456", "1E+3",
    "-1.23E-8", "999.999", "7", "-0.3", "12345678901234567890.123456789", "6.25E+5",
]

# 単項演算に使う値
UNARY_VALUES = PAIR_VALUES + [
    "2.5", "-2.5", "0.5", "-0.5", "5.5", "-5.5", "1.6", "-1.6", "1.1", "-1.1",
    "0.0005", "-999.5", "1.05", "-1.15", "-98765432109876543210987654321",
    "5E-10", "1.000", "100", "-0.125", "9.995", "0.000001", "0.0000001",
    "1.23E+20", "-4.5E-3", "600.0", "0E+3", "0E-10",
]


def text(d):
    """Swift には符号付きゼロがないので、ゼロは正にする。"""
    if d.is_zero():
        d = d.copy_abs()
    return str(d)


def quoted(value):
    return '"%s"' % value


def divided_with_scale(a, b, scale, rounding):
    """a / b を、スケール scale の位置で rounding により丸める。"""
    exact = Fraction(a) / Fraction(b) * (Fraction(10) ** scale)
    sign = -1 if exact < 0 else 1
    numerator, denominator = abs(exact.numerator), exact.denominator
    integer, remainder = divmod(numerator, denominator)
    # 捨てる部分を、半分との大小関係が同じ短い小数に置き換えて、丸めは decimal に任せる
    if remainder == 0:
        fraction = Decimal(0)
    elif 2 * remainder < denominator:
        fraction = Decimal("0.25")
    elif 2 * remainder == denominator:
        fraction = Decimal("0.5")
    else:
        fraction = Decimal("0.75")
    value = EXACT.add(Decimal(integer), fraction).copy_sign(Decimal(sign))
    rounded = value.quantize(Decimal(1), rounding=rounding, context=EXACT)
    return Decimal((rounded.as_tuple().sign, rounded.as_tuple().digits, -scale))


lines = []
emit = lines.append

emit("// 期待値は Python の decimal で計算した。")
emit("// 生成：python3 -I Tests/BigDecimalTests/Vectors.py > Tests/BigDecimalTests/Units/Vectors.swift")
emit("")

# 加減乗算と比較
emit("let arithmeticVectors: [(a: String, b: String, sum: String, difference: String, product: String, order: Int)] = [")
for a_text in PAIR_VALUES:
    for b_text in PAIR_VALUES:
        a, b = Decimal(a_text), Decimal(b_text)
        order = (a > b) - (a < b)
        emit("\t(%s, %s, %s, %s, %s, %d)," % (
            quoted(a_text), quoted(b_text),
            quoted(text(EXACT.add(a, b))),
            quoted(text(EXACT.subtract(a, b))),
            quoted(text(EXACT.multiply(a, b))),
            order,
        ))
emit("]")
emit("")

# 除算
emit("let divisionVectors: [(a: String, b: String, quotient: String, remainder: String, exactly: String?)] = [")
for a_text in PAIR_VALUES:
    for b_text in PAIR_VALUES:
        a, b = Decimal(a_text), Decimal(b_text)
        if b.is_zero():
            continue
        try:
            exactly = quoted(text(context(traps=[Inexact]).divide(a, b)))
        except Inexact:
            exactly = "nil"
        emit("\t(%s, %s, %s, %s, %s)," % (
            quoted(a_text), quoted(b_text),
            quoted(text(EXACT.divide_int(a, b))),
            quoted(text(EXACT.remainder(a, b))),
            exactly,
        ))
emit("]")
emit("")

emit("let divisionRoundingVectors: [(a: String, b: String, rule: String, scale2: String, precision5: String)] = [")
for a_text in PAIR_VALUES:
    for b_text in PAIR_VALUES:
        a, b = Decimal(a_text), Decimal(b_text)
        if b.is_zero():
            continue
        for name, rounding in RULES:
            emit("\t(%s, %s, %s, %s, %s)," % (
                quoted(a_text), quoted(b_text), quoted(name),
                quoted(text(divided_with_scale(a, b, 2, rounding))),
                quoted(text(context(prec=5, rounding=rounding).divide(a, b))),
            ))
emit("]")
emit("")

# 表現
emit("let representationVectors: [(value: String, description: String, plainString: String, normalized: String, precision: Int, isInteger: Bool, nearestDouble: String)] = [")
for value_text in UNARY_VALUES:
    d = Decimal(value_text)
    emit("\t(%s, %s, %s, %s, %d, %s, %s)," % (
        quoted(value_text),
        quoted(text(d)),
        quoted(format(d.copy_abs() if d.is_zero() else d, "f")),
        quoted(text(EXACT.normalize(d))),
        len(d.as_tuple().digits),
        "true" if d == d.to_integral_value() else "false",
        quoted(repr(float(d))),
    ))
emit("]")
emit("")

# 丸め
emit("let roundingVectors: [(value: String, rule: String, scaleMinus1: String, scale0: String, scale1: String, scale2: String, precision1: String, precision2: String, precision3: String, integer: String)] = [")
for value_text in UNARY_VALUES:
    d = Decimal(value_text)
    for name, rounding in RULES:
        scales = [
            text(d.quantize(Decimal((0, (1,), -scale)), rounding=rounding, context=EXACT))
            for scale in (-1, 0, 1, 2)
        ]
        precisions = [
            text(context(prec=precision, rounding=rounding).plus(d))
            for precision in (1, 2, 3)
        ]
        integer = str(int(d.to_integral_value(rounding=rounding)))
        fields = [value_text, name] + scales + precisions + [integer]
        emit("\t(" + ", ".join(quoted(v) for v in fields) + "),")
emit("]")

print("\n".join(lines))
