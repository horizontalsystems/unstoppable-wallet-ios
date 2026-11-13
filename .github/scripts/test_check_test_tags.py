import contextlib
import io
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_test_tags  # noqa: E402

WALLET_APP_ID = "${APP_ID || 'io.horizontalsystems.bankwallet.appcenter.e2e'}"


class CheckTestTagsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.original_cwd = os.getcwd()
        os.chdir(self.temp.name)

    def tearDown(self):
        os.chdir(self.original_cwd)
        self.temp.cleanup()

    def write(self, path, text):
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)
        with open(path, "w", encoding="utf-8") as file:
            file.write(textwrap.dedent(text))

    def tags(self, text):
        self.write(check_test_tags.TEST_TAGS, text)

    def flow(self, name, body, app_id=WALLET_APP_ID):
        self.write(f"flows/{name}.yaml", f"appId: {app_id}\n---\n" + textwrap.dedent(body))

    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
            code = check_test_tags.main(list(args))
        return code, out.getvalue()

    def git_base(self):
        subprocess.run(["git", "init", "-q"], check=True)
        subprocess.run(["git", "add", "-A"], check=True)
        subprocess.run(
            ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false",
             "commit", "-q", "-m", "base"],
            check=True,
        )

    def test_nested_parentheses_in_interpolation_match(self):
        self.tags(
            '''\
            enum TestTags {
                static func tab(_ name: String) -> String {
                    "tab_\\(name.lowercased())"
                }

                static func txItem(_ uid: String) -> String {
                    "tx_item_\\(uid.prefix(8))"
                }
            }
            '''
        )
        self.flow("a", "- tapOn:\n    id: tab_settings\n- tapOn:\n    id: tx_item_abc\n")
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertNotIn("::notice", out)
        self.assertIn("2 id selectors", out)

    def test_next_line_body_and_two_parameters_match(self):
        self.tags(
            '''\
            enum TestTags {
                static func termsCheck(_ index: Int) -> String {
                    "terms_check_\\(index)"
                }

                static func manageCoin(_ coinCode: String, _ blockchainUid: String) -> String {
                    "manage_coin_\\(coinCode)_\\(blockchainUid)"
                }
            }
            '''
        )
        self.flow(
            "a",
            "- tapOn:\n    id: manage_coin_BTC_bitcoin\n- tapOn:\n    id: terms_check_2\n",
        )
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertNotIn("::notice", out)
        self.assertIn("2 id selectors", out)

    def test_foreign_app_id_is_skipped_and_wallet_header_is_read(self):
        self.tags('enum TestTags {\n    static let known = "known"\n}\n')
        self.flow("foreign", "- tapOn:\n    id: undeclared_tag\n", app_id="com.apple.Preferences")
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertNotIn("::notice", out)
        self.assertIn("0 id selectors in 0 flows", out)

        self.flow("wallet", "- tapOn:\n    id: undeclared_tag\n")
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertIn("::notice", out)
        self.assertIn("undeclared_tag", out)
        self.assertIn("1 id selectors in 1 flows", out)

    def test_platform_branches(self):
        self.tags('enum TestTags {\n    static let known = "known"\n}\n')
        branch = """\
            - runFlow:
                when:
                  platform: {platform}
                commands:
                  - tapOn:
                      id: branch_tag
            """
        self.flow("android", branch.format(platform="Android"))
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertNotIn("branch_tag", out)

        os.remove("flows/android.yaml")
        self.flow("ios", branch.format(platform="iOS"))
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertIn("::notice", out)
        self.assertIn("branch_tag", out)

    def test_base_declared_and_removed_tag_fails(self):
        self.tags('enum TestTags {\n    static let removed = "removed_tag"\n    static let kept = "kept"\n}\n')
        self.flow("a", "- tapOn:\n    id: removed_tag\n")
        self.git_base()
        self.tags('enum TestTags {\n    static let kept = "kept"\n}\n')
        code, out = self.run_main("--base", "HEAD", "flows")
        self.assertEqual(code, 1)
        self.assertIn(
            "::error file=flows/a.yaml,line=4::Test tag 'removed_tag' was declared by the base",
            out,
        )

    def test_never_declared_tag_is_a_notice(self):
        self.tags('enum TestTags {\n    static let kept = "kept"\n}\n')
        self.flow("a", "- tapOn:\n    id: never_declared\n")
        self.git_base()
        code, out = self.run_main("--base", "HEAD", "flows")
        self.assertEqual(code, 0)
        self.assertIn("::notice", out)
        self.assertNotIn("::error", out)

    def test_without_base_nothing_fails(self):
        self.tags('enum TestTags {\n    static let removed = "removed_tag"\n}\n')
        self.flow("a", "- tapOn:\n    id: removed_tag\n")
        self.git_base()
        self.tags('enum TestTags {\n    static let kept = "kept"\n}\n')
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertIn("::notice", out)
        self.assertNotIn("::error", out)

    def test_nested_ids_are_found_with_their_line_numbers(self):
        self.tags('enum TestTags {\n    static let kept = "kept"\n}\n')
        self.flow(
            "a",
            """\
            - scrollUntilVisible:
                element:
                  id: scroll_target
            - tapOn:
                id: kept
            - runFlow:
                when:
                  visible:
                    id: conditional_target
                commands:
                  - tapOn: kept
            """,
        )
        code, out = self.run_main("flows")
        self.assertEqual(code, 0)
        self.assertIn("line=5::Test tag 'scroll_target'", out)
        self.assertIn("line=11::Test tag 'conditional_target'", out)
        self.assertEqual(out.count("::notice"), 2)


if __name__ == "__main__":
    unittest.main()
