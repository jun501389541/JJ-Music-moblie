# Reproducible commands and scope

Repository root: E:/Workspace/project/JJ-Music-mobile. No HEAD, staged files or remote; existing branch retained. Commands below use existing tools, no global config/install.

- `flutter --version`, `git --version`, existing JDK `java -version`: actual versions in report/doctor.
- `flutter doctor -v`: doctor.log contains network warning; not declared all-green.
- `./clients/flutter/tool/check.ps1 -Mode All -EvidenceDirectory <root>/docs/flutter-migration/evidence/bootstrap-20261031/final-checks`: final tool process exit0, contract hashes/format/analyze/tests/AndroidRelease/WindowsRelease each passes; lock file unchanged.
- cwd clients/flutter, `flutter test integration_test/diagnostic_smoke_test.dart --device-id windows --reporter expanded`: exit0,1 native smoke passes; temporary output copied to this evidence directory, original A01 screenshot preserved.
- SDK existing yaml parser via `dart --packages=E:/SDKs/flutter/packages/flutter_tools/.dart_tool/package_config.json graphflow-out/validate-bootstrap-workflow.dart`: exit0; structure/pins checked, not remote CI execution.
- Selected device only, `adb -s 35a63609 install -r <ordinary app-release.apk>`: Success; `adb ... shell am start -W -n dev.jjmusic.diagnostics.jj_music_mobile/.MainActivity`: Statusok but LaunchState UNKNOWN, screen Dozing; pidof present. No new UI interaction pass claim.
- Original19-file v2 hash check before edits; currentv2.1 checks in Quality. `git hash-object --path=<file>` vs `--no-filters` matches all19, no content-normalizing global Git changes.
- Source/config diff captured as raw UTF8 Git output; baseline prior94 source snapshot hashes verified, originalAGENTS matched historical MANIFEST; patch applied to isolated copy and exact current hashes checked. One generated Gradle HTML report is removed only from candidate-source snapshot via ignore rule; the on-disk report is retained, not deleted.

CI only prepared locally. Official Actions tag references were read through the GitHub connector after direct TLS failures; no repo write, remote creation or workflow execution. Independent reviewer unavailable (usage limit), not counted as independent approval. Remaining Android UI and first-cloud-run checks are explicit next steps.

Final selected-device check: adb35a63609 install returned device not found; devices-final.log has no connected phone. Earlier successful install/start/PID observations are separate and not substituted for final artifact/device UI verification. No new device selected automatically. 

