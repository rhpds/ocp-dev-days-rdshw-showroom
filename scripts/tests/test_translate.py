"""Offline integration checks: python3 -m unittest discover -s scripts/tests -v."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]


class TranslationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for folder in ('scripts', 'i18n', 'bin'):
            (self.root / folder).mkdir()
        shutil.copy(REPO / 'scripts/translate.sh', self.root / 'scripts/translate.sh')
        shutil.copy(REPO / 'i18n/config.yaml', self.root / 'i18n/config.yaml')
        self.en = self.root / 'content/en/modules/ROOT'
        self.ja = self.root / 'content/ja/modules/ROOT'
        for base in (self.en, self.ja):
            (base / 'pages/module-03/_shared').mkdir(parents=True)
            (base / 'pages/module-03/_figures').mkdir()
        for name in ('close-tabs', 'kaoto-intro'):
            (self.en / f'pages/module-03/_shared/{name}.adoc').write_text(f'English {name}\n')
            (self.ja / f'pages/module-03/_shared/{name}.adoc').write_text(f'Japanese {name}\n')
        (self.en / 'pages/index.adoc').write_text('English source\n')
        (self.ja / 'pages/index.adoc').write_text('Human translation\n')
        (self.en / 'pages/module-03/_figures/example.adoc').write_text('Technical figure\n')
        (self.ja / 'pages/module-03/_figures/example.adoc').write_text('Old figure\n')
        self.guide = self.root / 'content/ja/translation-guide.yml'
        self.guide.write_text('rules:\n  - rule: Keep prompts in English\nterms:\n  - en: namespace\n    ja: 名前空間\n')
        self.git('init', '-q')
        self.git('add', 'content/en')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@localhost', 'commit', '-qm', 'English source')
        self.commit = self.git('rev-parse', 'HEAD').strip()
        self.status = self.root / 'i18n/translation-status.json'
        self.status.write_text(json.dumps({'ja': {'pages/index.adoc': {
            'source_commit': self.commit, 'model': 'manual', 'guide_hash': self.hash_guide()
        }}}))
        # Stand-in records prompts and updates only the requested target; no API calls.
        fake = self.root / 'bin/opencode'
        fake.write_text('''#!/usr/bin/env python3
import os, pathlib, re, sys
prompt = sys.argv[-1]
with open('prompts.log', 'a') as f: f.write(prompt + '\\n---END---\\n')
if os.environ.get('FAIL_TRANSLATION'): sys.exit(1)
target = re.search(r'Write (?:the translated content|the updated translation) to ([^,\\s]+)', prompt).group(1).rstrip('.')
pathlib.Path(target).write_text('Updated translation\\n')
''')
        fake.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root / 'bin') + os.pathsep + os.environ['PATH'])

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True)

    def hash_guide(self):
        return self.git('hash-object', str(self.guide)).strip()

    def run_translate(self, *args, fail=False):
        env = dict(self.env)
        if fail:
            env['FAIL_TRANSLATION'] = '1'
        result = subprocess.run(['bash', str(self.root / 'scripts/translate.sh'), '--lang', 'ja',
                                 '--model', 'test/model', *args], cwd=self.root.parent,
                                env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def entry(self):
        return json.loads(self.status.read_text())['ja']['pages/index.adoc']

    def change_source(self):
        (self.en / 'pages/index.adoc').write_text('English source changed\n')
        self.git('add', 'content/en')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@localhost', 'commit', '-qm', 'Change source')

    def test_dry_run_preserves_status_and_shared_translations(self):
        before = self.status.read_bytes()
        output = self.run_translate('--dry-run')
        self.assertEqual(before, self.status.read_bytes())
        self.assertIn('Found 3 translatable files', output)
        self.assertEqual((self.ja / 'pages/module-03/_shared/close-tabs.adoc').read_text(), 'Japanese close-tabs\n')
        self.assertFalse((self.root / 'prompts.log').exists())

    def test_changed_history_with_identical_source_is_current(self):
        self.change_source()
        (self.en / 'pages/index.adoc').write_text('English source\n')
        self.git('add', 'content/en')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@localhost', 'commit', '-qm', 'Restore source')
        output = self.run_translate('--file', 'pages/index.adoc')
        self.assertIn('Stale (needs update): 0', output)
        self.assertIn('Current (source up to date): 1', output)
        self.assertFalse((self.root / 'prompts.log').exists())

    def test_guide_only_change_reports_without_retranslation(self):
        self.guide.write_text(self.guide.read_text() + 'exceptions: []\n')
        output = self.run_translate('--file', 'pages/index.adoc')
        self.assertIn('[GUIDE REVIEW] pages/index.adoc', output)
        self.assertFalse((self.root / 'prompts.log').exists())
        self.assertEqual((self.ja / 'pages/index.adoc').read_text(), 'Human translation\n')

    def test_guide_review_is_not_reported_as_stale_source(self):
        self.guide.write_text(self.guide.read_text() + 'exceptions: []\n')
        output = self.run_translate('--review-guide', '--file', 'pages/index.adoc', '--dry-run')
        self.assertIn('Stale (needs update): 0', output)
        self.assertIn('Current (source up to date): 1', output)
        self.assertIn('Guide-only updates selected: 1', output)
        self.assertIn('[GUIDE UPDATE] pages/index.adoc', output)
        self.assertNotIn('[STALE]', output)

    def test_explicit_guide_review_preserves_shared_and_syncs_figures(self):
        self.guide.write_text(self.guide.read_text() + 'exceptions: []\n')
        self.run_translate('--review-guide', '--file', 'pages/index.adoc')
        prompt = (self.root / 'prompts.log').read_text()
        self.assertIn('Review the entire existing translation', prompt)
        self.assertIn('Keep prompts in English', prompt)
        self.assertIn('Specific exceptions take precedence', prompt)
        self.assertEqual(self.entry()['guide_hash'], self.hash_guide())
        self.assertEqual((self.ja / 'pages/module-03/_shared/close-tabs.adoc').read_text(), 'Japanese close-tabs\n')
        self.assertEqual((self.ja / 'pages/module-03/_figures/example.adoc').read_text(), 'Technical figure\n')
        self.assertNotIn('[GUIDE REVIEW]', self.run_translate('--file', 'pages/index.adoc', '--dry-run'))

    def test_incremental_update_does_not_clear_pending_guide_review(self):
        old_hash = self.entry()['guide_hash']
        self.guide.write_text(self.guide.read_text() + 'exceptions: []\n')
        self.change_source()
        self.run_translate('--file', 'pages/index.adoc')
        self.assertEqual(self.entry()['guide_hash'], old_hash)
        self.assertEqual(self.entry()['source_commit'], self.git('rev-parse', 'HEAD').strip())
        prompt = (self.root / 'prompts.log').read_text()
        self.assertIn('Only update the sections', prompt)
        self.assertIn('Keep prompts in English', prompt)

    def test_new_shared_prose_uses_guide(self):
        target = self.ja / 'pages/module-03/_shared/kaoto-intro.adoc'
        target.unlink()
        self.run_translate('--file', 'pages/module-03/_shared/kaoto-intro.adoc')
        self.assertEqual(target.read_text(), 'Updated translation\n')
        self.assertIn('Keep prompts in English', (self.root / 'prompts.log').read_text())

    def test_legacy_status_requires_review_when_guide_exists(self):
        state = json.loads(self.status.read_text())
        state['ja']['pages/index.adoc'].pop('guide_hash')
        self.status.write_text(json.dumps(state))
        self.assertIn('[GUIDE REVIEW]', self.run_translate('--file', 'pages/index.adoc', '--dry-run'))
        self.run_translate('--file', 'pages/index.adoc', '--review-guide')
        self.assertEqual(self.entry()['guide_hash'], self.hash_guide())

    def test_bootstrapped_manual_translation_can_be_reviewed(self):
        self.run_translate('--file', 'pages/module-03/_shared/close-tabs.adoc', '--review-guide')
        self.assertIn('Review the entire existing translation', (self.root / 'prompts.log').read_text())

    def test_failure_does_not_mark_guide_reviewed(self):
        before = self.entry()
        self.guide.write_text(self.guide.read_text() + 'exceptions: []\n')
        self.run_translate('--review-guide', '--file', 'pages/index.adoc', fail=True)
        self.assertEqual(self.entry(), before)

    def test_legacy_status_without_guide_does_not_require_review(self):
        self.guide.unlink()
        state = json.loads(self.status.read_text())
        state['ja']['pages/index.adoc'].pop('guide_hash')
        self.status.write_text(json.dumps(state))
        self.assertNotIn('[GUIDE REVIEW]', self.run_translate('--file', 'pages/index.adoc', '--dry-run'))

    def test_no_guide_and_removed_guide(self):
        self.guide.unlink()
        self.assertIn('[GUIDE REVIEW]', self.run_translate('--file', 'pages/index.adoc', '--dry-run'))
        self.run_translate('--file', 'pages/index.adoc', '--review-guide')
        self.assertEqual(self.entry()['guide_hash'], 'none')
        self.assertNotIn('[GUIDE REVIEW]', self.run_translate('--file', 'pages/index.adoc', '--dry-run'))


if __name__ == '__main__':
    unittest.main()
