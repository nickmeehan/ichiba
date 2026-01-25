#!/usr/bin/env ruby
# frozen_string_literal: true

#
# init_skill.rb - Scaffold a new skill directory with template files
#
# Usage:
#   ruby scripts/init_skill.rb <skill-name> --path <output-directory>
#
# Example:
#   ruby scripts/init_skill.rb pdf-editor --path .claude/skills
#   => Creates .claude/skills/pdf-editor/ with template SKILL.md and example resources
#

require "fileutils"

SKILL_MD_TEMPLATE = <<~SKILL
  ---
  name: %{name}
  description: >
    TODO: [What it does - use action verbs like create, analyze, extract, generate].
    Use when [specific trigger conditions, keywords users would say, file types involved].
  ---

  # %{title}

  TODO: Write concise instructions for this skill. Remember:
  - Claude is already very smart; only add context it doesn't already have
  - Handle 80%% of use cases in the first 50 lines
  - Use imperative form ("Extract X" not "You should extract X")
  - Keep this file under 500 lines; split into references if needed

  ## Instructions

  TODO: Core workflow steps

  ## References

  TODO: Link to any bundled resources, or remove this section

  - **[Topic]**: See `./references/example.md`

  ## Scripts

  TODO: Document any scripts, or remove this section

  ```bash
  ruby scripts/example.rb [args]
  ```
SKILL

EXAMPLE_SCRIPT = <<~RUBY
  #!/usr/bin/env ruby
  # frozen_string_literal: true

  #
  # example.rb - Example script for %{name}
  #
  # Replace this with a real script or delete if not needed.
  #
  # Usage:
  #   ruby scripts/example.rb [args]
  #

  puts "Hello from %{name}!"
RUBY

EXAMPLE_REFERENCE = <<~MD
  # Example Reference

  This is an example reference file for %{name}.

  Replace this with real reference material (API docs, schemas, domain knowledge)
  or delete if not needed.

  Reference files are loaded into context on demand — use them for detailed
  information that would bloat SKILL.md.
MD

EXAMPLE_ASSET_README = <<~MD
  # Assets

  Place files used in output here (templates, images, fonts, boilerplate code).

  Assets are copied or modified during execution, not read into context.

  Delete this file and add real assets, or remove this directory if not needed.
MD

def validate_name(name)
  unless name.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
    abort "Error: Skill name must be lowercase with hyphens (e.g., 'my-skill')"
  end

  if name.match?(/anthropic|claude/)
    abort "Error: Skill name must not contain 'anthropic' or 'claude'"
  end

  if name.length > 64
    abort "Error: Skill name must be 64 characters or fewer"
  end
end

def title_from_name(name)
  name.split("-").map(&:capitalize).join(" ")
end

def create_skill(name, output_path)
  skill_dir = File.join(output_path, name)

  if Dir.exist?(skill_dir)
    abort "Error: Directory already exists: #{skill_dir}\n" \
          "Choose a different name or remove the existing directory."
  end

  title = title_from_name(name)
  vars = { name: name, title: title }

  # Create directory structure
  dirs = [
    skill_dir,
    File.join(skill_dir, "scripts"),
    File.join(skill_dir, "references"),
    File.join(skill_dir, "assets"),
  ]
  dirs.each { |dir| FileUtils.mkdir_p(dir) }

  # Write template files
  files = {
    File.join(skill_dir, "SKILL.md") => SKILL_MD_TEMPLATE % vars,
    File.join(skill_dir, "scripts", "example.rb") => EXAMPLE_SCRIPT % vars,
    File.join(skill_dir, "references", "example.md") => EXAMPLE_REFERENCE % vars,
    File.join(skill_dir, "assets", "README.md") => EXAMPLE_ASSET_README % vars,
  }

  files.each do |path, content|
    File.write(path, content)
  end

  # Make scripts executable
  FileUtils.chmod(0o755, File.join(skill_dir, "scripts", "example.rb"))

  puts "Skill '#{name}' created at #{skill_dir}"
  puts ""
  puts "  #{skill_dir}/"
  puts "  |- SKILL.md              # Edit: fill in TODOs"
  puts "  |- scripts/example.rb    # Replace or delete"
  puts "  |- references/example.md # Replace or delete"
  puts "  |- assets/README.md      # Replace or delete"
  puts ""
  puts "Next steps:"
  puts "  1. Edit SKILL.md — fill in the TODOs with your skill's content"
  puts "  2. Replace or remove example files in scripts/, references/, assets/"
  puts "  3. Run validate_skill.rb when ready:"
  puts "     ruby scripts/validate_skill.rb #{skill_dir}"
end

# --- CLI ---

def print_usage
  puts "Usage: ruby scripts/init_skill.rb <skill-name> --path <output-directory>"
  puts ""
  puts "Arguments:"
  puts "  <skill-name>       Lowercase hyphenated name (e.g., pdf-editor)"
  puts "  --path <dir>       Directory where the skill folder will be created"
  puts ""
  puts "Example:"
  puts "  ruby scripts/init_skill.rb pdf-editor --path .claude/skills"
end

if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
  print_usage
  exit 0
end

name = ARGV[0]
path_idx = ARGV.index("--path")

if path_idx.nil? || ARGV[path_idx + 1].nil?
  abort "Error: --path <output-directory> is required.\n\n#{`ruby #{__FILE__} --help`}"
end

output_path = ARGV[path_idx + 1]

unless Dir.exist?(output_path)
  abort "Error: Output directory does not exist: #{output_path}"
end

validate_name(name)
create_skill(name, output_path)
