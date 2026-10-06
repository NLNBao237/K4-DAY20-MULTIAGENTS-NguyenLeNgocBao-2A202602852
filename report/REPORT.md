# Báo cáo Lab: Self evolving Agentic

> Sao chép tệp này thành `report/REPORT.md` (đã làm ở Phần 0) và điền dần qua các Phần của lab. Xóa các dòng hướng dẫn dạng trích dẫn (bắt đầu bằng `>`). Văn phong kỹ thuật, ngắn gọn, mọi nhận định đi kèm số liệu hoặc bằng chứng. Trong buổi học: điền mục 1 đến 7 (bản nháp). Sau buổi học: hoàn thiện mục 8 đến 10.

## 1. Thông tin nhóm và cấu hình

| Họ tên | Mã sinh viên | Phần đóng góp |
|---|---|---|
| Nguyễn Lê Ngọc Bảo | 2A202602852 | Toàn bộ (làm cá nhân) |

- Nhà cung cấp và mô hình (`LAB_MODEL`, không ghi khóa API), nhiệt độ (`LAB_TEMPERATURE`), `recursion_limit`: `openai:gpt-4o-mini` qua một endpoint tương thích OpenAI (`OPENAI_BASE_URL`); `LAB_TEMPERATURE=0`; `recursion_limit=60` (mặc định).
- Phiên bản Deep Agents (`pip show deepagents`), hệ điều hành, chạy trực tiếp hay trong Docker: Deep Agents 0.7.21; máy chủ Windows 11, mọi lần chạy tác tử thực hiện **trong Docker** (image `python:3.12-slim` theo `Dockerfile` của kho, Python 3.12.15) vì shell của tác tử cần `/bin/sh`.
- Số lần chạy tác vụ đã dùng / ngân sách: 6 lần tính đến hết Phần 2 (baseline và subagents trên 3 tác vụ học). Không tính 8 lần chạy thử bằng mô hình khác trước khi đổi sang `gpt-4o-mini`; các lần đó đã bị loại và lưu riêng ở `results_gemini/` (xem Phụ lục).
- Commit của tag `freeze`:

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

> Chỉ dùng tác vụ học. Mỗi dòng là một check thất bại.

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

> Dán nội dung `report/table.md` và kết quả `python scripts/check_breakdown.py`. Nêu các lần chạy có `error` hoặc `skills_modified = true` (nếu có) và cách xử lý.

```text
(dán bảng ở đây)
```

## 8. Phân tích

> Trả lời từng câu bằng số liệu từ mục 7 và bằng chứng từ vết. Kết quả âm hoặc không có khác biệt vẫn hợp lệ nếu được phân tích tốt.

1. So với `baseline`, điều kiện nào cải thiện điểm tác vụ **học**? Điều kiện nào cải thiện điểm tác vụ **đánh giá**? Có điều kiện nào cải thiện tác vụ học nhưng không cải thiện tác vụ đánh giá? Nếu có, đó là dấu hiệu gì?
2. Tách điểm thành check kỹ thuật và check quy ước (`rule_`). Skill do curator sinh giúp nhóm check nào? Check quy ước **mới** của tác vụ đánh giá có được skill giúp không, và vì sao?
3. Dựa vào vết và `skills_read`, giải thích một check mà skill giúp đạt và một check mà skill không giúp (skill chưa được đọc, đọc nhưng không làm theo, skill thiếu hoặc sai).
4. Chi phí: so sánh số token trung bình giữa các điều kiện. Điều kiện nào có hiệu quả tốt nhất theo điểm trên mỗi token? Đa tác tử có đáng chi phí trong thí nghiệm này không?
5. Có dấu hiệu rò rỉ dữ liệu hoặc quá khớp nào trong skill sinh ra không? Nhóm đã phòng tránh như thế nào?
6. Nhiễu: so sánh điểm tác vụ học của cùng bộ skill ở Phần 3.4 (đã sao lưu) và sau đóng băng. Chênh lệch bao nhiêu? Nó cho biết điều gì về độ tin cậy của các chênh lệch trong bảng ở mục 7?

## 9. Hạn chế và tính hợp lệ

> Nêu ít nhất 3 hạn chế và ảnh hưởng của từng hạn chế đến kết luận (ví dụ: chỉ 3 tác vụ mỗi vai trò, mỗi cấu hình chạy một lần, nhiễu của mô hình, tác vụ do giảng viên thiết kế sẵn quy ước, chỉ một mô hình).

1.
2.
3.

## 10. Kết luận

> Tối đa 5 câu. Chỉ khẳng định điều số liệu hỗ trợ. Nêu một đề xuất cải tiến tiếp theo.

## Phụ lục

- Lệnh đã chạy (theo thứ tự), tất cả trong container (`docker run --rm -v "${PWD}:/lab" <image> ...`):
  1. `pytest tests/test_01_provided.py tests/test_02_agent.py tests/test_03_runner.py` (30 passed)
  2. `python -m lab.runner --condition baseline --tasks learn`
  3. `python -m lab.runner --condition subagents --tasks learn`
  4. `python scripts/check_breakdown.py` (chạy trên máy chủ vì cần `git`)
- Thử thách mở rộng (nếu có): hướng chọn, kết quả, nhận xét.
- Ghi chú khác:
  - **Line ending.** Kho được checkout trên Windows với `core.autocrlf=true`, làm tệp trong `tasks/*/workspace` thành CRLF; check `tests_not_modified` của code-learn so băm SHA-256 nên luôn thất bại dù tác tử không sửa test. Đã đặt `core.autocrlf=false` (cấu hình cục bộ) và checkout lại `tasks/` trước mọi lần chạy dùng trong báo cáo; băm của `test_report.py` khớp lại với `check.py`.
  - **Đổi mô hình.** 8 lần chạy đầu dùng `google_genai:gemini-3.5-flash-lite` (một phần dính lỗi CRLF nói trên, một lần lỗi 429 do hạn mức 15 request/phút). Sau khi đổi sang `gpt-4o-mini`, toàn bộ các lần đó bị loại khỏi so sánh và chuyển sang `results_gemini/`; mọi số liệu trong báo cáo đến từ một mô hình duy nhất.
  - **Lần chạy lỗi được giữ lại.** baseline/data-learn kết thúc bằng `GraphRecursionError`. Không chạy lại vì đây là hành vi của tác tử chứ không phải lỗi hạ tầng; chạy lại để lấy điểm tốt hơn sẽ là chọn lọc kết quả.
  - **Mở rộng trong `runner.py`.** Dùng `agent.stream(..., stream_mode="values")` thay cho `invoke` để giữ vết khi lần chạy lỗi (gợi ý ở `03_runner.md`, điểm 8); nhờ đó `trace.md` của lần chạy lặp vô hạn vẫn có 31 tool call.
  - **Tùy chọn `LAB_RPM`** trong `build_agent`: giới hạn số request mỗi phút cho gói API hạn mức thấp. Không được đặt trong các lần chạy dùng trong báo cáo.
