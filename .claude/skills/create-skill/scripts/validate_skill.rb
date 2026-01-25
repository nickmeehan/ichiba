#!/usr/bin/env ruby
# frozen_string_literal: true

#
# validate_skill.rb - Validate a skill directory before publishing
#
# Usage:
#   ruby scripts/validate_skill.rb <path-to-skill-directory>
#
# Example:
#   ruby scripts/validate_skill.rb .claude/skills/pdf-editor
#
# Checks:
#   - SKILL.md exists with valid frontmatter
#   - Name and description meet constraints
#   - No files nested deeper than one level
#   - No auxiliary docs (README.md in root, CHANGELOG.md, etc.)
#   - All relative path references in SKILL.md point to existing files
#   - Scripts have shebangs
#   - SKILL.md is under 500 lines
#

require "yaml"

class SkillValidator
  FORBIDDEN_NAME_WORDS = %w[anthropic claude].freeze
  MAX_NAME_LENGTH = 64
  MAX_DESCRIPTION_LENGTH = 1024
  MAX_SKILL_LINES = 500
  AUXILIARY_FILES = %w[README.md CHANGELOG.md INSTALLATION_GUIDE.md QUICK_REFERENCE.md].freeze
  NAME_PATTERN = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  attr_reader :skill_path, :errors, :warnings

  def initialize(skill_path)
    @skill_path = File.expand_path(skill_path)
    @errors = []
    @warnings = []
  end

  def validate
    check_skill_md_exists
    return report unless errors.empty?

    content = File.read(skill_md_path, encoding: "utf-8")
    frontmatter = parse_frontmatter(content)
    body = extract_body(content)

    check_frontmatter(frontmatter)
    check_body(body, content)
    check_structure
    check_auxiliary_files
    check_nesting_depth
    check_path_references(body)
    check_scripts

    report
  end

  private

  def skill_md_path
    File.join(skill_path, "SKILL.md")
  end

  def check_skill_md_exists
    unless File.exist?(skill_md_path)
      errors << "SKILL.md not found at #{skill_md_path}"
    end
  end

  def parse_frontmatter(content)
    match = content.match(/\A---\s*\n(.*?)\n---/m)
    unless match
      errors << "SKILL.md missing YAML frontmatter (---)"
      return {}
    end

    begin
      YAML.safe_load(match[1]) || {}
    rescue Psych::SyntaxError => e
      errors << "Invalid YAML frontmatter: #{e.message}"
      {}
    end
  end

  def extract_body(content)
    content.sub(/\A---\s*\n.*?\n---\s*\n/m, "")
  end

  def check_frontmatter(fm)
    # Name checks
    name = fm["name"]
    if name.nil? || name.strip.empty?
      errors << "Frontmatter missing required field: name"
    else
      unless name.match?(NAME_PATTERN)
        errors << "Name must be lowercase with hyphens and numbers only: '#{name}'"
      end

      if name.length > MAX_NAME_LENGTH
        errors << "Name exceeds #{MAX_NAME_LENGTH} characters (#{name.length})"
      end

      FORBIDDEN_NAME_WORDS.each do |word|
        if name.include?(word)
          errors << "Name must not contain '#{word}'"
        end
      end
    end

    # Description checks
    desc = fm["description"]
    if desc.nil? || desc.strip.empty?
      errors << "Frontmatter missing required field: description"
    else
      if desc.length > MAX_DESCRIPTION_LENGTH
        errors << "Description exceeds #{MAX_DESCRIPTION_LENGTH} characters (#{desc.length})"
      end

      action_verbs = %w[create generate extract analyze build process edit convert transform manage]
      has_action = action_verbs.any? { |v| desc.downcase.include?(v) }
      unless has_action
        warnings << "Description should include action verbs (create, generate, extract, etc.)"
      end

      unless desc.downcase.include?("use when") || desc.downcase.include?("when")
        warnings << "Description should include 'when to use' trigger conditions"
      end
    end

    # No extra fields
    allowed = %w[name description]
    extra = fm.keys - allowed
    extra.each do |key|
      warnings << "Unexpected frontmatter field: '#{key}' (only name and description are used)"
    end
  end

  def check_body(body, full_content)
    lines = full_content.lines
    if lines.length > MAX_SKILL_LINES
      errors << "SKILL.md is #{lines.length} lines (max #{MAX_SKILL_LINES})"
    end

    if body.strip.empty?
      warnings << "SKILL.md body is empty — add instructions"
    end

    if body.include?("TODO")
      warnings << "SKILL.md still contains TODO placeholders"
    end
  end

  def check_structure
    unless Dir.exist?(skill_path)
      errors << "Skill directory not found: #{skill_path}"
      return
    end

    # Check _shared is inside skill dir, not at root
    parent = File.dirname(skill_path)
    shared_at_parent = File.join(parent, "_shared")
    if Dir.exist?(shared_at_parent) && !skill_path.end_with?("_shared")
      warnings << "_shared/ found at parent level — should be inside skill directory"
    end
  end

  def check_auxiliary_files
    AUXILIARY_FILES.each do |aux|
      path = File.join(skill_path, aux)
      if File.exist?(path)
        errors << "Auxiliary file not allowed: #{aux} (skills should not include documentation files)"
      end
    end
  end

  def check_nesting_depth
    Dir.glob(File.join(skill_path, "**", "*")).each do |entry|
      next unless File.file?(entry)

      relative = entry.sub("#{skill_path}/", "")
      depth = relative.split("/").length - 1 # depth from skill root

      if depth > 2
        errors << "File nested too deeply (max 1 level): #{relative}"
      end
    end
  end

  def check_path_references(body)
    # Find relative path references like `./foo.md` or `./bar/baz.md`
    refs = body.scan(/`\.\/([^`]+)`/).flatten
    refs += body.scan(/\(\.\/([^)]+)\)/).flatten

    refs.uniq.each do |ref|
      full = File.join(skill_path, ref)
      unless File.exist?(full)
        errors << "Referenced path does not exist: ./#{ref}"
      end
    end
  end

  def check_scripts
    scripts_dir = File.join(skill_path, "scripts")
    return unless Dir.exist?(scripts_dir)

    Dir.glob(File.join(scripts_dir, "*")).each do |script|
      next if File.directory?(script)

      first_line = File.open(script, &:readline).strip rescue ""
      unless first_line.start_with?("#!")
        warnings << "Script missing shebang: #{File.basename(script)}"
      end
    end
  end

  def report
    puts "Validating skill: #{skill_path}"
    puts "=" * 60

    if errors.empty? && warnings.empty?
      puts "All checks passed!"
      puts ""
      return true
    end

    unless errors.empty?
      puts ""
      puts "ERRORS (#{errors.length}):"
      errors.each { |e| puts "  [x] #{e}" }
    end

    unless warnings.empty?
      puts ""
      puts "WARNINGS (#{warnings.length}):"
      warnings.each { |w| puts "  [!] #{w}" }
    end

    puts ""

    if errors.empty?
      puts "Passed with warnings."
      true
    else
      puts "Validation failed. Fix errors above and re-run."
      false
    end
  end
end

# --- CLI ---

if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
  puts "Usage: ruby scripts/validate_skill.rb <path-to-skill-directory>"
  puts ""
  puts "Example:"
  puts "  ruby scripts/validate_skill.rb .claude/skills/pdf-editor"
  exit 0
end

skill_path = ARGV[0]

unless Dir.exist?(skill_path)
  abort "Error: Directory not found: #{skill_path}"
end

validator = SkillValidator.new(skill_path)
success = validator.validate
exit(success ? 0 : 1)
