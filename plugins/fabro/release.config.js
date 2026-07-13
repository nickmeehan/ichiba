// Single-plugin adaptation of ichiba's per-plugin release config: one
// semantic-release run for the whole repo, plain conventionalcommits
// (no scope filtering), version written to .claude-plugin/plugin.json.
module.exports = {
  branches: ['main'],
  tagFormat: 'v${version}',
  plugins: [
    ['@semantic-release/commit-analyzer', { preset: 'conventionalcommits' }],
    ['@semantic-release/release-notes-generator', { preset: 'conventionalcommits' }],
    [
      '@semantic-release/exec',
      { prepareCmd: 'bash bin/release-bump.sh ${nextRelease.version}' },
    ],
    [
      '@semantic-release/git',
      {
        assets: ['.claude-plugin/plugin.json'],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
      },
    ],
    '@semantic-release/github',
  ],
};
