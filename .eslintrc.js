module.exports = {
  env: {
    node: true
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module'
  },
  settings: {
    'import/resolver': {
      typescript: {}
    }
  },
  plugins: ['unused-imports'],
  overrides: [
    {
      files: ['*.ts', '*.d.ts'],
      parserOptions: {
        project: './tsconfig.json'
      }
    }
  ],
  extends: ['eslint:recommended'],
  globals: {
    __dirname: true
  },
  rules: {
    'unused-imports/no-unused-imports': 'error',
    'no-unused-vars': 'off'
  }
}
