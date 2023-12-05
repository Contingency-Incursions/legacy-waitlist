# frozen_string_literal: true

module AuthService

  def self.requires_access(account, level)
    raise AccessDeniedError unless account.access.include?(level)
  end

  def self.requires_one_of_access(account, levels)
    has_access = false
    levels.split(',').each do |level|
      has_access = true if account.access.include?(level)
    end

    raise AccessDeniedError unless has_access
  end

  def self.get_access_keys(level)
    access_levels[level]
  end

  def self.access_levels
    Rails.cache.fetch('access_levels', expires_in: 5.days) do
      build_access_levels
    end
  end

  def self.build_access_levels
    def self.build_level(working, source, dest, keys)
      level = working[source].dup
      keys.each { |key| level << key }
      working[dest] = level
    end

    result = { 'user' => [] }

    build_level(
      result,
      'user',
      'Wiki Team',
      %w[wiki-editor]
    )

    build_level(
      result,
      'user',
      'Trainee',
      %w[
      fleet-configure
      fleet-invite
      fleet-view
      pilot-view
      waitlist-view
      waitlist-tag:TRAINEE
      fit-view
      skill-view
      waitlist-manage
    ]
    )

    build_level(
      result,
      'Trainee',
      'FC',
      %w[
      bans-manage
      badges-manage
      commanders-view
      fleet-activity-view
      fleet-history-view
      fit-history-view
      search
      skill-history-view
      waitlist-edit
      stats-view
      waitlist-tag:HQ-FC
      notes-view
      notes-add
    ]
    )

    build_level(
      result,
      'FC',
      'Instructor',
      %w[
      commanders-manage
      commanders-manage:Trainee
      commanders-manage:FC
      fleet-admin
      reports-view
    ]
    )

    build_level(
      result,
      'Instructor',
      'Leadership',
      %w[
      commanders-manage:Wiki\ Team
      commanders-manage:Instructor
      commanders-manage:Leadership
    ]
    )

    result
  end

  # the rest of the methods here...
end
