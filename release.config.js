const plugin = process.env.PLUGIN;

if (!plugin) {
  throw new Error('PLUGIN env var must be set (e.g. PLUGIN=dev-workflow)');
}

const parserOpts = {
  headerPattern: new RegExp(`^(\\w+)\\((${plugin})\\)(!)?: (.+)$`),
  headerCorrespondence: ['type', 'scope', 'breaking', 'subject'],
};

module.exports = {
  branches: ['main'],
  tagFormat: `${plugin}-v\${version}`,
  plugins: [
    [
      '@semantic-release/commit-analyzer',
      {
        preset: 'conventionalcommits',
        parserOpts,
        releaseRules: [
          { breaking: true, scope: plugin, release: 'major' },
          { revert: true, scope: plugin, release: 'patch' },
          { type: 'feat', scope: plugin, release: 'minor' },
          { type: 'fix', scope: plugin, release: 'patch' },
          { type: 'perf', scope: plugin, release: 'patch' },
        ],
      },
    ],
    [
      '@semantic-release/release-notes-generator',
      {
        preset: 'conventionalcommits',
        parserOpts,
      },
    ],
    [
      '@semantic-release/exec',
      {
        prepareCmd: `bash bin/release-bump.sh ${plugin} \${nextRelease.version}`,
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: [
          `plugins/${plugin}/.claude-plugin/plugin.json`,
          '.claude-plugin/marketplace.json',
        ],
        message: `chore(release): ${plugin} \${nextRelease.version} [skip ci]\n\n\${nextRelease.notes}`,
      },
    ],
    '@semantic-release/github',
  ],
};
