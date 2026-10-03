# chensuiyi/semver

Semantic versioning · 语义版本

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

语义版本:宽松解析、比较、major/minor/patch 递增。

- `parse` 刻意宽松:跳过任意前缀(`v`、产品名),停在首个非版本字符;预发布后缀(`1.4.0-beta`)按发布三元组比较;无数字得全零(可视为"未知版本")
- `compare` 逐段 ordering,返回 -1/0/1
- `bump` 递增一段、清零低位段

</td>
<td valign="top">

Semantic versioning: lenient parsing, comparison, major/minor/patch bumping.

- `parse` is deliberately lenient: any prefix is skipped (`v`, product names), scanning stops at the first non-version character; pre-release suffixes (`1.4.0-beta`) compare as their release triple; text without digits yields all zeros (treat as "unknown version")
- `compare` is segment-by-segment ordering: -1, 0, or 1
- `bump` increments one segment and zeroes the ones below

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `parse(text)` | 宽松解析;Lenient extraction of the first triple |
| `compare(a, b)` | -1 / 0 / 1 |
| `bump(v, kind)` | `Major` / `Minor` / `Patch` 递增;Increment one segment |
| `Semver::to_string` | `1.4.0` |

License: MIT
