# Báo cáo Lab: Self evolving Agentic

## 1. Thông tin nhóm và cấu hình

| Họ tên | Mã sinh viên | Phần đóng góp |
|---|---|---|
| Nguyễn Lê Ngọc Bảo | 2A202602852 | Toàn bộ (làm cá nhân) |

- Nhà cung cấp và mô hình (`LAB_MODEL`, không ghi khóa API), nhiệt độ (`LAB_TEMPERATURE`), `recursion_limit`: `openai:gpt-4o-mini` qua một endpoint tương thích OpenAI (`OPENAI_BASE_URL`); `LAB_TEMPERATURE=0`; `recursion_limit=60` (mặc định).
- Phiên bản Deep Agents (`pip show deepagents`), hệ điều hành, chạy trực tiếp hay trong Docker: Deep Agents 0.7.21; máy chủ Windows 11, mọi lần chạy tác tử thực hiện **trong Docker** (image `python:3.12-slim` theo `Dockerfile` của kho, Python 3.12.15) vì shell của tác tử cần `/bin/sh`.
- Số lần chạy tác vụ đã dùng / ngân sách: 25 lần chạy tác vụ bằng `gpt-4o-mini` (18 lần chính thức trong `results/`, 6 lần chạy thử Phần 3.4 cho hai bộ skill, 1 lần bị treo không có kết quả) và 3 lần gọi curator. Không tính 8 lần chạy thử bằng mô hình khác trước khi đổi sang `gpt-4o-mini`; các lần đó đã bị loại và lưu riêng ở `results_gemini/` (xem Phụ lục).
- Commit của tag `freeze`: `b80b407` (2026-10-06 17:30 +07:00); commit `hypotheses` đứng ngay trước là `692c3a5`.

## 2. Giả thuyết (commit TRƯỚC tag `freeze`, Phần 4.0)

Viết trước khi chạy bất kỳ tác vụ đánh giá nào; căn cứ chỉ gồm 9 lần chạy tác vụ học (mục 4, 5, 6). Dự đoán chung: không điều kiện nào vượt `baseline` một cách đáng tin trên tác vụ đánh giá.

- H1 (subagents so với baseline): điểm trung bình tác vụ đánh giá của `subagents` chênh `baseline` không quá 0,10 (theo hướng bất kỳ) và không check quy ước nào đạt. Căn cứ: trên tác vụ học tác tử chính chỉ giao việc 1/3 lần, hai vai trò `explorer` và `reviewer` chưa từng được gọi; lần giao việc duy nhất làm mất quy tắc của đề (doanh thu âm -355,75) và không được kiểm tra lại. Số token dự đoán tương đương `baseline` ở tác vụ không giao việc và cao hơn ở tác vụ có giao việc, tức là đa tác tử không đáng chi phí với mô hình này.
- H2 (skills-auto so với baseline): `skills-auto` không cải thiện điểm tác vụ đánh giá (chênh trong khoảng 0,10) và số check quy ước đạt vẫn bằng 0. Căn cứ: `skills_read` = 0 ở cả 6 lần chạy thử trên tác vụ học với hai bộ skill, nên skill không thể có tác dụng nếu không được đọc; bộ skill đóng băng chỉ phủ 2/9 quy ước của tác vụ học (type hints, changelog) cộng một quy trình kiểm tra JSON, và không chứa quy ước mới nào của tác vụ đánh giá. Kết quả này phù hợp với SkillsBench (skill do mô hình tự sinh trung bình không có lợi).
- H3 (tác vụ học so với tác vụ đánh giá): ở cả ba điều kiện, điểm tác vụ đánh giá không cao hơn điểm tác vụ học quá 0,10, và check của quy ước mới thất bại ở mọi điều kiện. Vì skill không cải thiện điểm tác vụ học (mục 6) nên cũng không có khoảng cách quá khớp kiểu SkillEvolBench: chênh lệch học-đánh giá của `skills-auto` dự đoán tương đương của `baseline`, và mọi chênh lệch dưới 0,15 được coi là nhiễu (hai lần chạy thử cùng điều kiện trên code-learn đã lệch nhau 4/10 so với 1/10).

## 3. Làm quen Deep Agents (Phần 0.3)

Nguồn: đầu ra của `python scripts/tour.py` (mô hình giả, không tốn token), Deep Agents 0.7.21.

1. **Công cụ mặc định.** Tác tử mặc định có 9 công cụ: 7 công cụ tệp (`ls`, `read_file`, `write_file`, `edit_file`, `delete`, `glob`, `grep`), 1 công cụ shell (`execute`) và 1 công cụ giao việc cho subagent (`task`). Chỉ `execute` cho phép chạy lệnh; nó chỉ hoạt động khi backend cài đặt `SandboxBackendProtocol`, nếu không sẽ trả về lỗi.
2. **Subagent `general-purpose`.** Mô tả của `task` nói đây là tác tử đa dụng để nghiên cứu câu hỏi phức tạp, tìm tệp và nội dung, và thực hiện tác vụ nhiều bước; nó có toàn bộ công cụ như tác tử chính ("This agent has access to all tools as the main agent"). Về ngữ cảnh: mỗi lần gọi là phi trạng thái (stateless), subagent **chỉ thấy lời giao việc (prompt)** mà tác tử chính viết, không thấy lịch sử hội thoại hay ý định của người dùng, và chỉ trả về một báo cáo cuối duy nhất. Hệ quả: mọi quy tắc của đề phải được chép vào lời giao việc, nếu không subagent sẽ không biết.
3. **System prompt rỗng, hành vi nằm trong mô tả công cụ.** `tour.py` in system prompt là `''`. Hướng dẫn hành vi đến từ mô tả công cụ:
   - `task`: "Put full detail in the prompt and state exactly what it should return".
   - `execute`: "You MUST avoid using search commands like find and grep. Instead use the grep, glob tools to search."

## 4. Đường cơ sở và phân loại lỗi (Phần 2.2)

Nguồn: `results/baseline/<tác vụ>/run.json` và `trace.md`. Tổng cộng 22/27 check thất bại (check kỹ thuật đạt 5/18, check quy ước đạt 0/9 theo `scripts/check_breakdown.py`).

| Tác vụ | Check thất bại | Nhóm lỗi (A-G) | Bằng chứng (trích ngắn từ `detail` hoặc vết) |
|---|---|---|---|
| code-learn | `parse_price_all_formats` | A | `detail`: "wrong for: ['(12.00)']". Docstring của `parse_price` có nêu dạng số âm kiểu kế toán, tác tử chỉ thêm `cleaned.replace(",", "")`. |
| code-learn | `csv_quoting_follows_docstring` | A | `detail`: "to_csv_row returned 'Desk, large "oak",10.00,2'". Docstring yêu cầu bọc tên có dấu phẩy hoặc nháy kép; test có sẵn không phủ nên tác tử không sửa. |
| code-learn | `rule_type_hints` | E | "RULE: every public function ... has type annotations on all parameters and on the return value." |
| code-learn | `rule_regression_tests` | E | "RULE: add tests/test_regressions.py with one test function per bug you fixed (at least 3)". |
| code-learn | `rule_changelog` | E | "RULE: record each fix in CHANGELOG.md under the heading '## Unreleased' ...". |
| data-learn | `north_q1_revenue`, `north_q1_orders`, `top_region`, `missing_amount_orders`, `duplicate_rows_removed` (5 check) | G (lặp vô hạn, không tạo đầu ra) | `error`: "GraphRecursionError: Recursion limit of 60 reached"; `detail`: "FileNotFoundError ... workspace/answer.json". Vết: `import pandas` thất bại (sandbox không có pandas), sau đó tác tử ghi lại `workspace/script.py` rồi chạy `python3 workspace/script.py` hơn 10 lần, lần nào cũng dừng ở cùng một lỗi cú pháp tại "script.py, line 22"; 31 tool call, 309.038 token. |
| data-learn | `rule_money_in_cents`, `rule_meta_block` | G (bị che) | Cùng `FileNotFoundError`: không có `answer.json` nên không đánh giá được quy ước. Nhiều khả năng vẫn là E nếu tệp tồn tại, nhưng lần chạy này không chứng minh được. |
| data-learn | `rule_clean_csv` | E | "RULE: write workspace/clean.csv with the header order_id,timestamp_utc,region,amount_cents ...". |
| logs-learn | `valid_structure`, `entry_count`, `timestamps_utc`, `exception_fields`, `repeat_counts`, `counts_by_service` (6 check) | B (kèm A, D) | `detail`: "JSONDecodeError: Expecting property name enclosed in double quotes: line 1 column 2". Vết chỉ có 3 tool call: `read_file` app.log hai lần rồi `write_file` errors.json viết tay, nội dung bắt đầu bằng `{\\n  "errors"` (ký tự `\n` thoát hai lần nên JSON hỏng). Không chạy lệnh nào để kiểm tra tệp (B), không đọc `workspace/README.md` dù đề yêu cầu (A), và trong nội dung ghi có `"timestamp_utc": "2024-05-01T01:04:08-05:00"` chưa đổi sang UTC (D). |
| logs-learn | `rule_service_names`, `rule_sorted_errors`, `rule_schema_header` | B (bị che) | Cùng `JSONDecodeError`; quy ước không đánh giá được vì tệp không đọc được. |

Tổng hợp theo nhóm (số check): A = 2, B = 9 (một nguyên nhân gốc), E = 4, G = 7 (một nguyên nhân gốc), C = 0, D = 0 check riêng (chỉ xuất hiện như nguyên nhân phụ ở logs-learn), F = 0.

Nhận xét:

- Khác với kỳ vọng trong GUIDE ("mô hình mạnh: phần lớn lỗi thuộc nhóm E"), với `gpt-4o-mini` lỗi kỹ thuật chiếm đa số: 13/18 check kỹ thuật thất bại, đến từ ba nguyên nhân gốc (bỏ qua docstring ở code-learn; lặp sửa một lỗi cú pháp ở data-learn; ghi JSON viết tay mà không kiểm chứng ở logs-learn). Không có bằng chứng phủ định cho nhóm A và B.
- Nhóm E vẫn hệ thống nhất: 0/9 check quy ước đạt, và mọi check quy ước đánh giá được (4 check) đều thất bại với `detail` bắt đầu bằng `RULE:`. Tác tử không thể biết các quy ước này vì chúng không có trong đề.
- Skill có thể phòng ngừa nhóm E (skill mang đúng thông tin còn thiếu: tệp phải có, định dạng, tên khóa). Skill cũng có thể giảm nhóm B bằng quy tắc thủ tục ("sinh tệp bằng script, sau đó `json.load` lại để kiểm tra"; "đọc README trước"). Skill khó sửa nhóm G vì đó là giới hạn năng lực của mô hình khi tự gỡ lỗi; nếu lần chạy vẫn không tạo được đầu ra thì quy ước trong skill cũng không được chấm.
- F không xuất hiện theo đúng định nghĩa (tệp `errors.json` có tồn tại), nhưng câu trả lời cuối của logs-learn khẳng định tệp "adheres to the s[tructure]" trong khi tệp không phải JSON hợp lệ: báo cáo hoàn thành chưa được kiểm chứng.

## 5. Điều kiện `subagents` (Phần 2.3)

- Các subagent đã định nghĩa (tên, vai trò, lý do thiết kế): ba subagent trong `src/lab/subagents.py`, chia theo giai đoạn để mỗi vai trò có ngữ cảnh riêng và không tự chấm việc của mình.
  - `explorer`: chỉ đọc (README, docstring, test, mẫu dữ liệu), báo cáo quy tắc kèm tệp và dòng, liệt kê dữ liệu bẩn. Nhằm vào nhóm lỗi A và D.
  - `implementer`: thực hiện thay đổi, chạy test hoặc script, đọc lại tệp đầu ra. Nhằm vào nhóm C.
  - `reviewer`: kiểm tra độc lập từng yêu cầu, đánh dấu PASS/FAIL kèm bằng chứng, không sửa. Nhằm vào nhóm B và F.
- `subagent_calls` ở từng tác vụ và nhận xét (kể cả trường hợp bằng 0):

  | Tác vụ | `subagent_calls` | Subagent được gọi | Điểm (baseline -> subagents) |
  |---|---|---|---|
  | code-learn | 0 | không | 5/10 -> 6/10 |
  | data-learn | 1 | `implementer` (1 lần) | 0/8 -> 1/8 |
  | logs-learn | 0 | không | 0/9 -> 0/9 |

  Ở 2/3 tác vụ tác tử chính không giao việc dù `SUBAGENTS_NOTE` yêu cầu "For anything beyond a trivial step, delegate". Đây là kết quả hợp lệ: `SUBAGENTS_NOTE` chỉ là lời khuyến khích, và `gpt-4o-mini` đi thẳng vào hành động (code-learn: đọc 4 tệp rồi `write_file` ngay; logs-learn: 3 tool call giống hệt baseline, cùng lỗi `JSONDecodeError`). `explorer` và `reviewer` không được gọi lần nào, nên hai vai trò nhằm vào nhóm A và B chưa hề được thử. Chênh lệch 5/10 -> 6/10 ở code-learn không thể quy cho subagent vì không có lần giao việc nào; đó là nhiễu giữa hai lần chạy.
- Thông tin thiếu hoặc thừa khi giao việc (nếu có giao việc): chỉ có một lần giao việc (data-learn, cho `implementer`).
  - Thiếu: không nhắc `workspace/README.md`, nên subagent không biết `-999` nghĩa là thiếu giá trị, không biết có ba định dạng ngày và cách viết vùng không thống nhất. Biên thời gian bị rút gọn thành "from 2024-01-01 to 2024-03-31", mất "00:00 UTC up to and including 23:59:59 UTC". Mất câu "Orders with a missing amount must not be added to any revenue" và ràng buộc "exactly these keys".
  - Hệ quả đo được: `north_q1_revenue: wrong value (got -355.75)` (doanh thu âm, dấu hiệu đã cộng `-999`), `missing_amount_orders: wrong value (got 0)`, `top_region: wrong value (got 'East')`.
  - Không kiểm tra báo cáo: tác tử chính chép nguyên báo cáo của subagent làm câu trả lời cuối, không chạy lại lệnh nào, không đặt câu hỏi về doanh thu âm, dù prompt yêu cầu "Check what a subagent returns before you rely on it".
  - Thừa: trước khi giao việc, tác tử chính tự ghi một `answer.json` giữ chỗ toàn giá trị 0.
- Ảnh hưởng đến token và thời gian:

  | Tác vụ | Token baseline | Token subagents | Giây baseline | Giây subagents |
  |---|---|---|---|---|
  | code-learn | 51.772 | 50.709 | 46,1 | 44,9 |
  | data-learn | 309.038 (lặp tới giới hạn đệ quy) | 59.236 | 212,2 | 98,8 |
  | logs-learn | 19.684 | 21.156 | 18,4 | 22,8 |
  | Trung bình | 126.831 | 43.700 | 92,2 | 55,5 |

  Trung bình của baseline bị kéo lên bởi một lần chạy lặp vô hạn, nên không thể kết luận subagents rẻ hơn. Ở hai tác vụ không giao việc, chi phí gần như bằng nhau (chênh dưới 8%; phần thêm là mô tả subagent trong công cụ `task` và `SUBAGENTS_NOTE`). Ở tác vụ duy nhất có giao việc không có số baseline sạch để so sánh. Lưu ý `trace.md` chỉ chứa luồng chính: 59.236 token của data-learn gồm cả phần bên trong `implementer` (token được cộng qua callback), trong khi luồng chính chỉ có 3 tool call.

## 6. Self-evolving: skill do curator sinh (Phần 3)

- Số lần chạy curator, số skill bị xóa và lý do: 3 lần (lần đầu và đủ 2 lần chạy lại cho phép), 3 skill bị xóa. Không sửa tay nội dung skill nào; giữa các lần chỉ sửa prompt của curator trong `src/lab/curator.py`.

  | Lần | Kết quả | Xử lý và lý do |
  |---|---|---|
  | 1 | 0 skill hợp lệ. Mô hình sinh `handle_file_operations`, `adhere_to_conventions`, `implement_testing_protocols`; cả ba bị `validate_skill` loại với "invalid name" (dấu gạch dưới). | Thêm vào prompt quy tắc đặt tên kèm ví dụ, chạy lại. |
  | 2 | 3 skill hợp lệ: `check-output-format`, `enforce-type-annotations`, `maintain-changelog`. Chạy thử Phần 3.4: 4/10, 2/8, 0/9, `skills_read` = 0/3. | Xóa cả 3 (lưu ở `results_dev/skills-curator-run2/`, kết quả chạy thử ở `results_dev/skills-auto-curator-run2/`). Lý do: không lần chạy nào đọc skill, và `check-output-format` chỉ nói chung chung ("Verify that the output file name matches the required naming convention") mà không nêu quy ước cụ thể nào; cả bộ thiếu 7/9 quy ước trong phản hồi. Thêm vào prompt yêu cầu một skill cho mỗi loại tác vụ, liệt kê mọi dòng `RULE:` và các bước quy trình. |
  | 3 | 3 skill hợp lệ, là bộ được đóng băng (bảng dưới). | Giữ nguyên dù chất lượng chưa tốt: đã hết số lần chạy lại. |

  Curator không làm theo yêu cầu "một skill cho mỗi loại tác vụ": cả ba lần đều cho skill theo từng quy tắc. Bộ cuối cùng vẫn thiếu 7/9 quy ước của tác vụ học (`tests/test_regressions.py`, tiền theo cent, khối `meta`, `clean.csv`, tên dịch vụ, thứ tự sắp xếp, `schema_version`) và không có skill nào cho phân tích dữ liệu dạng bảng.

| Skill | Tổng quát hay riêng cho tác vụ học? | Đúng hay sai (nêu chỗ sai nếu có) | Độ dài, `description` và `skills_read` ở Phần 3.4 |
|---|---|---|---|
| `check-python-function-annotations` | Tổng quát: nêu một quy ước theo loại lỗi, không có tên tệp, hàm hay con số của tác vụ học. | Đúng: bước 1 chép nguyên phản hồi của `rule_type_hints`. Bước 3 ("Run the code analysis tools") mơ hồ, không nêu công cụ nào, nhưng không gây hại. | 4 dòng thân. `description` quá hẹp: "Use when ensuring that all public functions ... have type annotations" mô tả chính quy tắc chứ không mô tả tình huống kích hoạt (sửa một gói Python), nên tác tử chỉ nhận ra khi đã biết quy tắc. `skills_read` = 0. |
| `write-changelog-entries` | Tổng quát. `CHANGELOG.md` và `## Unreleased` là tên do quy ước Acme yêu cầu nên được phép. | Đúng: khớp phản hồi của `rule_changelog` (tiêu đề, dạng `- fix(<function name>): <short description>`, ít nhất 3 mục). "Include at least three entries" có thể khiến tác tử thêm mục thừa khi chỉ sửa ít hơn 3 lỗi. | 4 dòng thân. `description` hẹp: "Use when documenting changes ... in a changelog"; đề bài sửa lỗi không nhắc changelog nên không kích hoạt. `skills_read` = 0. |
| `validate-json-output` | Tổng quát về quy trình, nhưng bước 1 ("property names ... enclosed in double quotes") là chép lại thông báo `JSONDecodeError` của một lần chạy, tức là triệu chứng chứ không phải nguyên nhân (viết tay JSON với `\n` thoát hai lần). | Không sai nhưng thiếu: không nêu cách kiểm tra cụ thể (sinh tệp bằng script, `json.load` lại), và không chứa quy ước nào của họ logs hay data (ba `RULE:` của logs-learn bị che bởi lỗi JSON nên curator không nhìn thấy). | 4 dòng thân. `description` tốt nhất trong ba skill ("Use when generating JSON output files from logs or data processing") và khớp trực tiếp với logs-learn, data-learn; vẫn `skills_read` = 0. |

Kết quả Phần 3.4 với bộ skill đóng băng (sao lưu ở `results/skills-auto-dev/`):

| Tác vụ | baseline | skills-auto (3.4) | `skills_read` | Token baseline -> skills-auto |
|---|---|---|---|---|
| code-learn | 5/10 | 1/10 | 0 | 51.772 -> 10.401 |
| data-learn | 0/8 | 2/8 | 0 | 309.038 -> 147.832 |
| logs-learn | 0/9 | 0/9 | 0 | 19.684 -> 16.833 |

- Skill không được đọc ở lần chạy nào, dù `SKILLS_NOTE` yêu cầu "As your FIRST action, read the SKILL.md of every skill whose description could apply". Đã kiểm tra harness bằng mô hình giả: system prompt có liệt kê đủ ba skill kèm đường dẫn `/skills/<tên>/SKILL.md` và `read_file` đọc được tệp, nên đây là hành vi của mô hình chứ không phải lỗi nạp skill.
- Vì skill không được đọc, mọi chênh lệch so với `baseline` ở bảng trên là nhiễu giữa các lần chạy, không phải tác dụng của skill. Ví dụ code-learn 1/10: vết chỉ có 5 tool call (một `glob` và bốn `read_file`), không có lệnh sửa nào, nhưng câu trả lời cuối liệt kê "Changes Made" cho bốn hàm. Đây là lỗi nhóm F (báo cáo hoàn thành sai sự thật), chưa xuất hiện ở `baseline`.
- logs-learn lặp lại đúng lỗi của `baseline` (viết tay JSON hỏng, 2 tool call) dù có sẵn skill `validate-json-output` nhằm vào chính lỗi đó.

## 7. Kết quả so sánh (Phần 4.3, 4.4)

`report/table.md` (sinh bởi `python -m lab.compare`; mỗi ô là một lần chạy):

| Task | baseline | subagents | skills-auto |
|---|---|---|---|
| code-learn | 5/10 | 6/10 | 1/10 |
| data-learn | 0/8 | 1/8 | 3/8 |
| logs-learn | 0/9 | 0/9 | 0/9 |
| code-eval | 1/11 | 5/11 | 3/11 |
| data-eval | 2/9 | 2/9 | 1/9 |
| logs-eval | 0/10 | 0/10 | 1/10 |
| **Mean score - learning tasks** | 0.17 | 0.24 | 0.16 |
| **Mean score - evaluation tasks** | 0.10 | 0.23 | 0.16 |
| **Mean tokens per run** | 78,036 | 60,401 | 108,069 |
| **Runs that read a skill** | 0/6 | 0/6 | 0/6 |

`python scripts/check_breakdown.py`:

```text
condition     role    technical  house rules  mean tokens  read a skill
baseline      eval      3/18         0/12          29,240      0/3
baseline      learn     5/18         0/9          126,831      0/3
subagents     eval      7/18         0/12          77,101      0/3
subagents     learn     7/18         0/9           43,700      0/3
skills-auto   eval      5/18         0/12         114,047      0/3
skills-auto   learn     4/18         0/9          102,091      0/3
```

`python scripts/verify_freeze.py`: `checked 6 runs of skill conditions: OK` (chạy trong container Linux; xem ghi chú về Windows ở Phụ lục).

Các lần chạy có `error` (cả ba là `GraphRecursionError: Recursion limit of 60 reached`):

| Lần chạy | Điểm | Tool call | Token | Diễn biến trong vết |
|---|---|---|---|---|
| baseline / data-learn | 0/8 | 31 | 309.038 | Ghi lại và chạy `workspace/script.py` hơn 10 lần với cùng một lỗi cú pháp ở dòng 22. |
| skills-auto / code-learn | 1/10 | 44 | 220.761 | 13 lần `edit_file` giống hệt nhau trên `pricing.py` xen kẽ 11 lần chạy pytest. |
| skills-auto / code-eval | 3/11 | 34 | 211.373 | 11 lần `edit_file` giống hệt nhau trên `timeutil.py` xen kẽ 8 lần chạy pytest. |

Cả ba được giữ nguyên, không chạy lại: đây là hành vi của tác tử (lặp một thao tác không có tiến triển), không phải lỗi hạ tầng, và mục "Xử lý sự cố" của GUIDE yêu cầu ghi nhận vào `error` rồi giải thích. Chạy lại cho đến khi không lỗi sẽ làm đẹp số liệu của đúng những điều kiện gặp lỗi. Nhờ dùng `agent.stream`, vết của ba lần này vẫn đầy đủ. Không có lần chạy nào có `skills_modified = true`.

Đối chiếu giả thuyết (mục 2) với số liệu:

| Giả thuyết | Dự đoán | Quan sát | Kết luận |
|---|---|---|---|
| H1 | Chênh lệch điểm đánh giá subagents so với baseline không quá 0,10; check quy ước đạt = 0 | 0,23 so với 0,10 (chênh 0,12); quy ước 0/12 | Ngưỡng số bị vượt nhẹ, nhưng cơ chế dự đoán đúng: toàn bộ chênh lệch đến từ code-eval (1/11 lên 5/11), nơi `subagent_calls` = 0. Xem mục 8, câu 1. |
| H2 | skills-auto không cải thiện (trong 0,10); check quy ước đạt = 0 | 0,16 so với 0,10 (chênh 0,06); quy ước 0/12; `skills_read` 0/6 | Đúng. |
| H3 | Điểm đánh giá không cao hơn điểm học quá 0,10; quy ước mới thất bại ở mọi điều kiện | baseline 0,17 xuống 0,10; subagents 0,24 xuống 0,23; skills-auto 0,16 và 0,16; ba check quy ước mới thất bại 9/9 lần | Đúng. |

## 8. Phân tích

1. **Điều kiện nào cải thiện điểm.** Tác vụ học: `subagents` cao hơn `baseline` 0,07 (0,24 so với 0,17), `skills-auto` thấp hơn 0,01 (0,16). Tác vụ đánh giá: `subagents` cao hơn 0,12 (0,23 so với 0,10), `skills-auto` cao hơn 0,06 (0,16). Không điều kiện nào cải thiện tác vụ học mà không cải thiện tác vụ đánh giá, nên không có dấu hiệu quá khớp. Tuy nhiên không chênh lệch nào quy được cho cơ chế của điều kiện:
   - `subagents`: cả hai tác vụ code có `subagent_calls` = 0, mà chính code-eval tạo ra toàn bộ khoảng cách (5/11 so với 1/11). Lần chạy `baseline` trên code-eval chỉ có 6 tool call (một `glob`, năm `read_file`), không sửa tệp nào nhưng câu trả lời cuối viết "Updated the `billable_blocks` function to correctly round up using `math.ceil`" (lỗi nhóm F), nên chỉ đạt `tests_not_modified`. Ở hai tác vụ data, nơi có giao việc thật (mỗi tác vụ 1 lần), điểm là 1/8 và 2/9, không hơn `baseline` ở tác vụ đánh giá (2/9).
   - `skills-auto`: `skills_read` = 0 ở cả 6 lần, nên skill không thể là nguyên nhân của bất kỳ chênh lệch nào.
2. **Check kỹ thuật và check quy ước.** Check quy ước đạt 0/21 ở cả ba điều kiện (0/9 học, 0/12 đánh giá). Check kỹ thuật: baseline 5/18 và 3/18, subagents 7/18 và 7/18, skills-auto 4/18 và 5/18 (học và đánh giá). Skill do curator sinh không giúp nhóm check nào. Ba check quy ước mới của tác vụ đánh giá (`rule_version_bump`, `rule_sorted_keys_format`, `rule_source_line`) thất bại ở cả 9 lần chạy. Skill không thể giúp các check này vì hai lý do độc lập: skill không được đọc, và dù được đọc thì curator chỉ thấy phản hồi của tác vụ học nên bộ skill không chứa quy ước mới. Cần lưu ý nhiều check quy ước bị che: khi tệp đầu ra thiếu hoặc không phải JSON hợp lệ, `detail` là `JSONDecodeError` hoặc `FileNotFoundError` chứ không phải `RULE:`, tức là quy ước chưa hề được đánh giá. Điều này xảy ra ở cả ba lần chạy logs-learn và ở baseline/data-learn; với tác vụ đánh giá `detail` bị ẩn nên không xác nhận được, nhưng 5/6 lần chạy họ logs không đạt cả `valid_structure`.
3. **Một check skill giúp và một check skill không giúp.** Không có check nào skill giúp đạt: trong 12 lần chạy có nạp skill (6 chính thức, 6 chạy thử) không lần nào có `read_file` vào `skills/`.
   - Check skill không giúp, do chưa được đọc: `rule_changelog`. Skill `write-changelog-entries` chứa đúng quy tắc ("Record each fix in CHANGELOG.md under the heading '## Unreleased'"), nhưng ở skills-auto/code-learn và code-eval tác tử đi thẳng vào `glob` rồi `read_file` mã nguồn; check thất bại ở cả hai.
   - Check đạt ở `skills-auto` nhưng không nhờ skill: `valid_structure` của logs-eval (điều kiện duy nhất đạt check này). Vết cho thấy tác tử viết `workspace/parse_log.py`, chạy ba lần, đọc lại `errors.json` rồi ghi đè bằng tay một tệp JSON hợp lệ; `skills_read` = 0 nên skill `validate-json-output` không tham gia. Nội dung vẫn sai (`"service": "INFO"`), 9 check còn lại thất bại.
   - Trường hợp "đọc nhưng không làm theo" và "skill thiếu" không quan sát được trực tiếp vì chưa lần nào skill được đọc; riêng "skill thiếu" đã được xác định khi đánh giá ở mục 6 (thiếu 7/9 quy ước).
4. **Chi phí.** Token trung bình mỗi lần chạy: baseline 78.036, subagents 60.401, skills-auto 108.069. Điểm trung bình trên 100.000 token: baseline 0,17, subagents 0,39, skills-auto 0,15. Thứ hạng này do ba lần chạy lặp vô hạn quyết định (baseline/data-learn 309.038 token; skills-auto/code-learn 220.761 và code-eval 211.373), không do thiết kế của điều kiện. So sánh sạch hơn là trên lần chạy có giao việc thật: data-eval tốn 131.362 token ở `subagents` so với 44.894 ở `baseline` (gấp 2,9 lần) cho cùng điểm 2/9. Kết luận: đa tác tử không đáng chi phí trong thí nghiệm này; nơi nó được dùng thì đắt hơn mà không tốt hơn, nơi điểm cao hơn thì nó không được dùng.
5. **Rò rỉ và quá khớp.** Không có dấu hiệu rò rỉ: curator chỉ nạp `run.json` có `role == "learn"`, `validate_skill` không tìm thấy định danh nào của tác vụ đánh giá trong ba skill, skill không chứa tên tệp dữ liệu, tên hàm hay con số của tác vụ học, và `verify_freeze.py` xác nhận cả 6 lần chạy dùng đúng bộ skill đã đóng băng. Một dấu hiệu quá khớp nhẹ ở mức nội dung: `write-changelog-entries` yêu cầu "at least three entries", con số gắn với số lỗi của tác vụ học. Không đo được quá khớp ở mức điểm vì skill không tạo ra cải thiện nào trên tác vụ học để mà mất đi. Biện pháp phòng tránh đã dùng: viết giả thuyết và commit trước tag `freeze`, không xem tác vụ đánh giá trước khi đóng băng, không sửa tay skill. Phần 6c (Phụ lục) cho thấy các lớp phòng vệ này vẫn có lỗ hổng.
6. **Nhiễu.** Cùng bộ skill đóng băng, tác vụ học: Phần 3.4 cho 1/10, 2/8, 0/9 (trung bình 0,12); sau đóng băng cho 1/10, 3/8, 0/9 (trung bình 0,16). Chênh 0,04 chỉ do chạy lại. Điểm giống nhau còn che khác biệt lớn về hành vi: code-learn đạt 1/10 cả hai lần, nhưng lần đầu là 5 tool call và 10.401 token (không sửa gì), lần sau là 44 tool call và 220.761 token (lặp tới giới hạn đệ quy), tức token chênh 21 lần. Rộng hơn, vì skill không được đọc và subagent không được gọi ở tác vụ code, năm lần chạy code-learn (baseline 5/10, subagents 6/10, hai lần skills-auto 1/10, bộ skill đã xóa 4/10) gần như là năm lần lặp của cùng một tác tử, với biên độ 0,5 trên một tác vụ. Khoảng cách lớn nhất trong bảng mục 7 là 0,12 trên trung bình của ba tác vụ, nằm trong mức nhiễu này. Không chênh lệch nào trong bảng đủ tin cậy để xếp hạng ba điều kiện, dù `LAB_TEMPERATURE=0`.

## 9. Hạn chế và tính hợp lệ

1. **Mỗi ô chỉ một lần chạy, nhiễu lớn hơn hiệu ứng.** Biên độ quan sát trên một tác vụ (0,5) lớn hơn mọi khoảng cách giữa các điều kiện (tối đa 0,12). Mọi so sánh "điều kiện A hơn điều kiện B" trong báo cáo vì thế chỉ mang tính mô tả; kết luận duy nhất vững là các kết luận về cơ chế đọc từ vết (skill không được đọc, subagent hiếm khi được gọi).
2. **Chỉ ba tác vụ mỗi vai trò.** Trung bình của ba giá trị bị một tác vụ chi phối: toàn bộ lợi thế của `subagents` trên tác vụ đánh giá đến từ một lần chạy code-eval.
3. **Một mô hình, và là mô hình yếu so với tác vụ.** `gpt-4o-mini` không tạo được đầu ra hợp lệ ở phần lớn lần chạy (họ logs: 5/6 lần không đạt cả `valid_structure`), không làm theo `SKILLS_NOTE` và `SUBAGENTS_NOTE`. Kết quả "skill không có tác dụng" vì vậy thực chất là "skill không được đọc bởi mô hình này"; nó không cho biết skill có giúp một mô hình mạnh hơn hay không. README đã cảnh báo mô hình yếu cho kết quả không đại diện.
4. **Check quy ước bị che bởi lỗi kỹ thuật.** Khi tệp đầu ra thiếu hoặc hỏng, check quy ước thất bại mà không đánh giá quy ước. Tỉ lệ 0/21 vì thế trộn hai hiện tượng (không biết quy ước, và không tạo được tệp), và curator chỉ nhìn thấy 4/9 quy ước của tác vụ học dưới dạng `RULE:`, góp phần làm bộ skill thiếu.
5. **Tác vụ và quy ước do giảng viên thiết kế.** Các quy ước Acme được chọn để không suy ra được từ đề, nên thí nghiệm đo khả năng truyền tri thức ẩn chứ không đo lợi ích của skill nói chung.
6. **Môi trường.** Chạy qua một endpoint trung gian tương thích OpenAI với độ trễ thất thường (baseline/code-eval mất 406 giây cho 6 tool call; một lần chạy bị treo hơn 10 phút), nên cột thời gian không dùng được để so sánh. Sandbox không cô lập hệ thống tệp (Phần 6c), dù không vết nào cho thấy tác tử đọc ra ngoài `workspace/`.

## 10. Kết luận

Với `gpt-4o-mini`, cả đa tác tử lẫn skill tự sinh đều không cải thiện kết quả một cách đo được: check quy ước đạt 0/21 ở mọi điều kiện và mọi khoảng cách về điểm (tối đa 0,12) nằm trong mức nhiễu giữa các lần chạy lặp (tới 0,5 trên một tác vụ). Nguyên nhân nằm ở khâu sử dụng chứ không ở khâu đánh giá: skill không được đọc lần nào trong 12 lần chạy, và subagent chỉ được gọi ở 2/6 lần chạy, nơi nó tốn gấp 2,9 lần token cho cùng điểm. Bộ skill của curator hợp lệ về định dạng nhưng chỉ phủ 2/9 quy ước, một phần vì lỗi kỹ thuật của baseline đã che các quy ước còn lại. Thí nghiệm không có dấu hiệu rò rỉ hay quá khớp, nhưng cũng không đủ sức để phát hiện một hiệu ứng nhỏ. Đề xuất tiếp theo: lặp lại với một mô hình gọi công cụ ổn định hơn và ít nhất 3 lần chạy mỗi ô, đồng thời đưa nội dung skill vào thẳng system prompt thay vì trông chờ tác tử tự đọc, để tách câu hỏi "skill có đúng không" khỏi câu hỏi "skill có được đọc không".

## Phụ lục

- Lệnh đã chạy (theo thứ tự), tất cả trong container (`docker run --rm -v "${PWD}:/lab" <image> ...`):
  1. `pytest tests/test_01_provided.py tests/test_02_agent.py tests/test_03_runner.py` (30 passed)
  2. `python -m lab.runner --condition baseline --tasks learn`
  3. `python -m lab.runner --condition subagents --tasks learn`
  4. `python -m lab.curator` (3 lần, xem mục 6) và `python -m lab.runner --condition skills-auto --tasks learn` (2 lần, cho hai bộ skill)
  5. `git add -A && git commit -m "hypotheses: ..."`, rồi `git commit --allow-empty -m "freeze skills" && git tag freeze`
  6. `python -m lab.runner --condition baseline --tasks eval`, `--condition subagents --tasks eval`, `--condition skills-auto --tasks all` (8 lần chạy cuối trong 12 lần này chạy qua `results_dev/run_batch.sh`: mỗi tác vụ một tiến trình, giới hạn 20 phút)
  7. `python scripts/verify_freeze.py`, `python -m lab.compare > report/table.md`, `python scripts/check_breakdown.py`
  8. `python results_dev/redteam.py` (Phần 6c, không tốn token)
- Thử thách mở rộng: **6c, tấn công curator và sandbox.** Thực hiện ngoại tuyến bằng mô hình giả và thư mục tạm (`results_dev/redteam.py`, đầu ra ở `results_dev/redteam_output.txt`); không ghi gì vào `skills/auto` hay `results/`, thực hiện sau khi đã có đủ kết quả chính thức.

  ```text
  eval_markers(): ['bookings', 'code-eval', 'data-eval', 'logs-eval', 'orders', 'orders.json', 'worker', 'worker.log']
  
  == 1. validate_skill so với bản chuẩn hóa ==
  variant                      validate_skill   normalised check
  plain marker                 REJECTED         REJECTED
  hyphen -> space              accepted         REJECTED
  hyphen -> underscore         accepted         REJECTED
  zero-width space inside      accepted         REJECTED
  fullwidth letters            accepted         REJECTED
  paraphrase, no identifier    accepted         accepted
  
  == 2. Chỉ dẫn cài trong trace.md đi thẳng vào prompt của curator ==
  injected text reached the curator prompt: True
  harmful skill written to disk: ['read-the-checker']
  
  == 3. Shell của tác tử đọc được gì ngoài sandbox ==
  list the eval tasks      -> 3
  read an eval checker     -> 138
  read .env (size only)    -> 818
  API key in shell env     -> 0
  ```

  Ba phát hiện và biện pháp chặn đề xuất:
  1. **`validate_skill` chỉ so khớp chuỗi nguyên văn.** Định danh của tác vụ đánh giá lọt qua khi đổi dấu gạch ngang thành dấu cách hoặc gạch dưới, chèn ký tự zero-width, hoặc dùng chữ fullwidth. Biện pháp: chuẩn hóa NFKC và bỏ mọi ký tự không phải chữ cái hoặc chữ số trước khi so (cột "normalised check" chặn được cả bốn biến thể). Diễn đạt lại không dùng định danh ("the held-out variant ... bump the package version") thì không bộ lọc chuỗi nào chặn được; biện pháp thật sự là quy trình: curator không bao giờ được nạp dữ liệu đánh giá, và người đọc từng skill trước khi đóng băng.
  2. **Prompt injection qua vết.** `curate_skills` chép 6000 ký tự cuối của `trace.md` vào prompt, mà vết chứa đầu ra công cụ do tác tử và dữ liệu tác vụ tạo ra. Một chỉ dẫn cài trong đó đi thẳng tới curator, và skill có hại ("đọc checker của tác vụ") được ghi ra đĩa vì hợp lệ về định dạng. Biện pháp: bọc vết trong dấu phân cách và nói rõ đó là dữ liệu chứ không phải chỉ dẫn; chỉ đưa vào prompt tên lệnh gọi công cụ thay vì kết quả công cụ; từ chối skill chứa đường dẫn ra ngoài `workspace/` hoặc `skills/`.
  3. **Shell của tác tử không bị giam trong sandbox.** `virtual_mode=True` chỉ áp dụng cho công cụ tệp; `execute` chạy với quyền của tiến trình, nên từ sandbox trong `/tmp` tác tử liệt kê được thư mục tác vụ đánh giá, đọc được `check.py` (lời giải của bài chấm) và đọc được `.env` chứa khóa API. `inherit_env=False` chỉ che biến môi trường (0 biến khóa trong shell), không che tệp. Biện pháp: chạy tác tử bằng một người dùng không có quyền đọc thư mục kho, hoặc chỉ mount sandbox vào container chạy tác tử và chấm điểm ở tiến trình bên ngoài; truyền khóa bằng `--env-file` thay vì để `.env` trong thư mục được mount. Đã rà soát mọi lệnh gọi công cụ trong `trace.md` của `results/`: không lệnh nào của luồng chính chạm đường dẫn ngoài sandbox, và không có khóa nào xuất hiện trong kết quả. Việc subagent làm bên trong không hiện trong vết nên không rà soát được.
- Ghi chú khác:
  - **Line ending.** Kho được checkout trên Windows với `core.autocrlf=true`, làm tệp trong `tasks/*/workspace` thành CRLF; check `tests_not_modified` của code-learn so băm SHA-256 nên luôn thất bại dù tác tử không sửa test. Đã đặt `core.autocrlf=false` (cấu hình cục bộ) và checkout lại `tasks/` trước mọi lần chạy dùng trong báo cáo; băm của `test_report.py` khớp lại với `check.py`.
  - **Đổi mô hình.** 8 lần chạy đầu dùng `google_genai:gemini-3.5-flash-lite` (một phần dính lỗi CRLF nói trên, một lần lỗi 429 do hạn mức 15 request/phút). Sau khi đổi sang `gpt-4o-mini`, toàn bộ các lần đó bị loại khỏi so sánh và chuyển sang `results_gemini/`; mọi số liệu trong báo cáo đến từ một mô hình duy nhất.
  - **Lần chạy lỗi được giữ lại.** baseline/data-learn kết thúc bằng `GraphRecursionError`. Không chạy lại vì đây là hành vi của tác tử chứ không phải lỗi hạ tầng; chạy lại để lấy điểm tốt hơn sẽ là chọn lọc kết quả.
  - **Mở rộng trong `runner.py`.** Dùng `agent.stream(..., stream_mode="values")` thay cho `invoke` để giữ vết khi lần chạy lỗi (gợi ý ở `03_runner.md`, điểm 8); nhờ đó `trace.md` của lần chạy lặp vô hạn vẫn có 31 tool call.
  - **Tùy chọn `LAB_RPM`** trong `build_agent`: giới hạn số request mỗi phút cho gói API hạn mức thấp. Không được đặt trong các lần chạy dùng trong báo cáo.
  - **Lần chạy bị treo.** Ở lượt chạy chính thức đầu tiên, subagents/data-eval không trả về sau hơn 10 phút (nhiều khả năng một lệnh gọi API không phản hồi) và bị dừng khi chưa ghi `run.json`. Lần chạy lại là kết quả duy nhất được ghi cho ô này; không có kết quả nào bị thay thế.
  - **`verify_freeze.py` trên Windows.** Chạy trực tiếp trên Windows script báo sai "skills differ from the frozen skills" vì `hash_skills` băm cả đường dẫn tương đối, mà Windows dùng `\` còn các lần chạy trong container dùng `/`. Chạy trong container Linux (cùng nền tảng với các lần chạy) cho kết quả `OK`.
  - **Thư mục phụ.** `results/skills-auto-dev/` là kết quả Phần 3.4 của bộ skill đóng băng; `results_dev/` chứa bộ skill đã xóa, kết quả chạy thử của nó và mã Phần 6c; `results_gemini/` chứa các lần chạy bằng mô hình cũ. `lab.compare` chỉ đọc ba thư mục điều kiện trong `results/`.
