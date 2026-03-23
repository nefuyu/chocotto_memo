# Skill: Resolve GitHub Issue with TDD

## 目的
GitHubのIssueを読み取り、テスト駆動開発（TDD）で安全に機能を実装する。

## 手順
1. `gh issue list` で未着手のIssueを確認し、内容を詳細に分析する。
2. **【重要】仕様の検証**:
   - もし不明点や矛盾があれば、`gh issue comment` で質問を書き込み、その時点でタスクを「保留」として終了せよ。
3. （不明点がなければ）`git checkout -b task/issue-[ID]` でブランチ作成。
4. **テストの作成**: Issueの仕様を満たすテストケースを `test/` 内に作成する。
5. **実装**: テストがパスするように `lib/` 内のコードを実装・修正する。
6. **検証**: `flutter test` を実行し、すべてのテストがパスすることを確認する。
7. **完了**: 変更を `git add .` し、`git commit -m "feat: resolve issue #[ID]"` でコミットする。