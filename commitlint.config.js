const fs = require('node:fs');
const path = require('node:path');

const pluginsDir = path.join(__dirname, 'plugins');
const pluginScopes = fs
  .readdirSync(pluginsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name);

const allowedNonPluginScopes = ['deps', 'release'];

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [...pluginScopes, ...allowedNonPluginScopes]],
    'scope-case': [2, 'always', 'kebab-case'],
  },
};
