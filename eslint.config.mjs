import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import security from 'eslint-plugin-security';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  {
    ignores: [
      '**/dist/**',
      '**/node_modules/**',
      '**/*.config.*',
      '**/generated/**', // machine-generated (e.g. apps/web/src/generated/release-notes.generated.ts)
      'infra/**',
      'charts/**',
      '.claude/**',
      '.venv/**',
      'spike/**',
      // Gitignored local scratch: design-sync's generated bundle and its build
      // output. CI never checks these out, so linting them made `pnpm lint`
      // red locally and green remotely — which is worse than not running it,
      // because AGENTS.md's definition of done requires it to pass.
      '.ds-sync/**',
      'ds-bundle/**',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  security.configs.recommended,
  {
    rules: {
      // argus hygiene — the hard invariants are enforced by Semgrep; these are guardrails.
      'no-console': 'warn',
      '@typescript-eslint/no-explicit-any': 'warn',
      'security/detect-object-injection': 'off',
    },
  },
  {
    // Build and verify CLIs. Printing IS their interface — they report what
    // they checked and exit non-zero — and the paths they read are their own
    // build output, taken from argv, not from anything a user controls.
    files: ['**/scripts/**/*.{mjs,js,ts}'],
    rules: {
      'no-console': 'off',
      'security/detect-non-literal-fs-filename': 'off',
    },
  },
  prettier,
);
