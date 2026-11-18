# APIと検証観点

- Number.init(String/UInt/integerLiteral)、description、比較、incremented:
  先頭ゼロ・非ASCII・負数の拒否、桁数無制限、桁の繰り上げ。
- SemanticVersion.init/parse、major/minor/patch/prerelease/build/description:
  必須3要素、識別子と先頭ゼロ、ビルドメタデータ、無効文字、不完全形式。
- == / < / hash: 仕様例の優先順位、数値とASCII比較、メタデータを除外した整合性。
- majorIncremented/minorIncremented/patchIncremented: コア加算と下位リセット、付加情報の除去。
- Codable: 全情報の文字列往復、不正形式のデコード拒否。
