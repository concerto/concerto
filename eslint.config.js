import pluginVue from 'eslint-plugin-vue'
import js from '@eslint/js'
import stylistic from '@stylistic/eslint-plugin'

export default [
  // add more generic rulesets here, such as:
  js.configs.recommended,
  ...pluginVue.configs['flat/recommended'],
  {
    plugins: {
      '@stylistic': stylistic,
    },
    rules: {
      'indent': ['error', 2],
      // override/add rules settings here, such as:
      // 'vue/no-unused-vars': 'error'
    }
  }
]