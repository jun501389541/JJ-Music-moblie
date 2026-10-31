# 自有技术夹具 v2（P1诊断）

本项目确定性生成，不读取个人媒体或账号。生成的测试音及本说明按CC0-1.0提供。

- tone-a.wav：440Hz，PCM16LE、mono、8000Hz、0.5秒，8044字节。
- tone-b.wav：660Hz，同格式/长度。
- tone-long.wav：440Hz，PCM16LE、mono、16000Hz、12秒，384044字节，幅度1500；由tool/generate_long_fixture.dart生成。
- 原始短音由tool/generate_fixtures.dart生成；occurrence-a/b可指向同一tone-a，验证条目身份不能用trackKey代替。
- A03/A05已实际解码这些样本；不是全部格式支持或人工听感通过。坏文件是测试临时目录中自行写入的4字节文件，不修改本目录原件。
- 摘要见SHA256SUMS；当前冻结见docs/flutter-migration/evidence/A02/20261031-freeze.md，旧v1保留历史。
