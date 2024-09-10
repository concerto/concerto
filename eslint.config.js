import pluginVue from 'eslint-plugin-vue'
import js from '@eslint/js'

export default [
  // add more generic rulesets here, such as:
  js.configs.recommended,
  ...pluginVue.configs['flat/recommended'],
  {
    rules: {
      // override/add rules settings here, such as:
      // 'vue/no-unused-vars': 'error'
    }
  }
]