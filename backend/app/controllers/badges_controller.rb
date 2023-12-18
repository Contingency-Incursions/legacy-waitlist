# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :set_badge, only: [:assign]
  before_action :set_character, only: [:assign]
  before_action :check_duplicate, only: [:assign]
  before_action :check_exclusion, only: [:assign]
  def index
    AuthService.requires_access(@authenticated_account, "badges-manage")

    badges = Badge.select('badge.*, (SELECT COUNT(*) FROM badge_assignment WHERE badge_assignment.badgeid = badge.id) as member_count')
                  .map do |badge|
      {
        id: badge.id,
        name: badge.name,
        member_count: badge.member_count,
        exclude_badge_id: -1
      }
    end

    render json: badges
  end

  def assign
    AuthService.requires_access(@authenticated_account, "badges-manage")

    badge_assignment = BadgeAssignment.new(
      characterid: @character.id,
      badgeid: @badge.id,
      grantedbyid: @authenticated_account.id,
      grantedat: DateTime.now
    )

    if badge_assignment.save
      render plain: "OK"
    else
      render plain: badge_assignment.errors.full_messages.join(", "), status: :unprocessable_entity
    end
  end

  def revoke
    AuthService.requires_access(@authenticated_account, "badges-manage")

    badge_assignment = BadgeAssignment.find_by(characterid: params[:character_id], badgeid: params[:id])

    if badge_assignment.nil?
      render plain: "Badge assignment not found", status: :not_found
    else
      badge_assignment.destroy
      render plain: "OK"
    end
  end

  def get_badge_members
    AuthService.requires_access(@authenticated_account, "badges-manage")
    @badge_assignments = BadgeAssignment
                           .joins(:character, :granted_by, :badge)
                           .where(badge_id: params[:badge_id])

    # Map these records to the desired output structure
    @badge_assignments = @badge_assignments.map do |assignment|
      {
        badge: {
          id: assignment.badge.id,
          name: assignment.badge.name,
          member_count: -1,
          exclude_badge_id: -1
        },
        granted_at: assignment.granted_at,
        character: {
          id: assignment.character.id,
          name: assignment.character.name
        },
        granted_by: {
          id: assignment.granted_by.id,
          name: assignment.granted_by.name
        }
      }
    end

    # render json or plain depending on data availability
    if @badge_assignments.empty?
      render plain: "No Content", status: 204
    else
      render json: @badge_assignments, status: :ok
    end
  end

  private


  def set_badge
    @badge = Badge.find_by(id: params[:id])

    if @badge.nil?
      render plain: "Badge not found (ID: #{params[:id]})", status: :not_found
    end
  end

  def set_character
    @character = Character.find_by(id: params[:badge][:id])

    if @character.nil?
      render plain: "Character not found (ID: #{params[:badge][:id]})", status: :not_found
    end
  end

  def check_duplicate
    if BadgeAssignment.find_by(characterid: @character.id, badgeid: @badge.id)
      render plain: "#{@character.name} already has #{@badge.name} and cannot be assigned it a second time", status: :bad_request
    end
  end

  def check_exclusion
    if @badge.exclude_badge_id.present?
      excluded_badge = BadgeAssignment.joins(:badge)
                                      .where("badge_assignment.characterid = ? AND badge.id = ?", @character.id, @badge.exclude_badge_id)
                                      .select("badge.name")
                                      .first
      if excluded_badge.present?
        render plain: "Cannot assign #{@badge.name} to #{@character.name} while they have been assigned #{excluded_badge.name}", status: :bad_request
      end
    end
  end

end
