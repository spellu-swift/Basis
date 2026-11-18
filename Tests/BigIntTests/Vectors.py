# BigIntTests の期待値（Units/Vectors.swift）を生成する。
import random
random.seed(20261102)
M = 2**64
special = [0, 1, M - 1, M - 2, 2**63, 2**63 - 1]
def word():
    return random.choice(special) if random.random() < 0.5 else random.randrange(M)
def number(n):
    v = 0
    for i in range(n):
        v = v * M + word()
    if random.random() < 0.5:
        v = -v
    return v
def trunc_div(a, b):
    q = abs(a) // abs(b)
    if (a < 0) != (b < 0):
        q = -q
    return q, a - q * b
cases = []
for _ in range(60):
    a = number(random.randint(1, 6))
    b = number(random.randint(1, 4))
    if b == 0:
        b = 1
    cases.append((a, b))
# Knuth D add-back を起こしやすい組
cases.append((2**192 - 1, 2**128 - 2**64 + 1))
cases.append(((M - 1) * M**3 + (M - 2) * M**2, (M - 1) * M + (M - 1)))
cases.append((2**256, 2**128 + 1))
cases.append((-(2**200 + 12345), 2**64 + 3))
print("// 期待値は Python の int で計算した。")
print("// 生成：python3 -I Tests/BigIntTests/Vectors.py > Tests/BigIntTests/Units/Vectors.swift")
print("let arithmeticVectors: [(a: String, b: String, sum: String, difference: String, product: String, quotient: String, remainder: String, and: String, or: String, xor: String)] = [")
for a, b in cases:
    q, r = trunc_div(a, b)
    vals = [a, b, a + b, a - b, a * b, q, r, a & b, a | b, a ^ b]
    print("\t(" + ", ".join('"%d"' % v for v in vals) + "),")
print("]")
print()
print("let representationVectors: [(decimal: String, hex: String, bitWidth: Int, trailingZeroBitCount: Int, shiftedLeft70: String, shiftedRight70: String, shiftedRight3: String, inverted: String)] = [")
values = sorted({v for pair in cases for v in pair} | {0, 1, -1, 2**64, -(2**64), 2**63, -(2**63), 2**64 - 1, -(2**64 - 1), 2**128, -(2**128)}, key=lambda v: (abs(v), v))
for v in values:
    width = (v.bit_length() if v >= 0 else (~v).bit_length()) + 1
    tz = (v & -v).bit_length() - 1 if v != 0 else 1
    h = ("-" if v < 0 else "") + format(abs(v), "x")
    print('\t("%d", "%s", %d, %d, "%d", "%d", "%d", "%d"),' % (v, h, width, tz, v << 70, v >> 70, v >> 3, ~v))
print("]")
