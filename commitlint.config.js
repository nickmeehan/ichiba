const fs = require('node:fs');
const path = require('node:path');

const pluginsDir = path.join(__dirname, 'plugins');

// Vendored plugins are synced from their upstream repos and never edited
// here, so their names are not valid commit scopes. See
// .github/vendored-plugins.
const vendoredFile = path.join(__dirname, '.github', 'vendored-plugins');
const vendoredScopes = fs.existsSync(vendoredFile)
  ? fs
      .readFileSync(vendoredFile, 'utf8')
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#'))
      .map((line) => line.split(/\s+/)[0])
  : [];

const pluginScopes = fs
  .readdirSync(pluginsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .filter((name) => !vendoredScopes.includes(name));

const allowedNonPluginScopes = ['deps', 'release'];

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [...pluginScopes, ...allowedNonPluginScopes]],
    'scope-case': [2, 'always', 'kebab-case'],
  },
};
