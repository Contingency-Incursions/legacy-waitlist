# frozen_string_literal: true

class CommandersController < ApplicationController
  before_action :authenticate!, except: [:public_list]
  def create
    AuthService.requires_access(@authenticated_account, 'commanders-manage')

    # Record creation parameters
    character_id = params[:character_id]
    role = params[:role]

    # Additional validation
    if character_id.nil?
      render plain: 'Request body missing required property character_id', status: :bad_request
      return
    end

    # Ensure the requested role exists
    # This piece of code could vary based on how you defined your "get_access_keys" method in your application.
    role_keys = AuthService.get_access_keys(role)
    if role_keys.nil?
      render plain: "The FC rank \"#{role}\" does not exist", status: :bad_request
      return
    end

    # Ensure the authenticated user has permission to assign this role
    required_scope = "commanders-manage:#{role}"
    unless @authenticated_account.access.include?(required_scope)
      render plain: "You do not have permission to grant the role \"#{role}\"", status: :forbidden
      return
    end

    # Check if admin record already exists
    admin_record = Admin.find_by(character_id: character_id)
    if admin_record
      render plain: "Cannot assign \"#{role}\" to #{admin_record.character.name} as they already have a role",
             status: :bad_request
      return
    end

    # Fetch character first
    character = Character.find_by(id: character_id)
    if character
      # Insert new admin role
      Admin.create(character_id: character_id, role: role, granted_at: Time.now.utc, granted_by_id: @authenticated_account.id)
      render plain: 'OK', status: :ok
    else
      render plain: 'Not Found', status: :not_found
    end
  end
  def revoke
    AuthService.requires_access(@authenticated_account, 'commanders-manage')

    # Parse parameters and fetch corresponding record
    character_id = params[:id]
    admin_record = Admin.find_by(character_id: character_id)

    # Prevent the user from revoking their own role
    if @authenticated_account.id.to_s == character_id
      render plain: 'You cannot revoke your own rank.', status: :bad_request
      return
    end

    # If the target user has a role...
    if admin_record
      # Ensure the authenticated user is allowed to revoke the role
      required_scope = "commanders-manage:#{admin_record.role}"
      unless @authenticated_account.access.include?(required_scope)
        render plain: "You do not have permission to revoke the role \"#{admin_record.role}\"", status: :forbidden
        return
      end

      # Revoke the role
      admin_record.destroy
    end

    render plain: 'OK', status: :ok
  end
  def lookup
    AuthService.requires_access(@authenticated_account, 'commanders-manage')

    admin = Admin.find_by(character_id: params[:id])

    if admin
      render plain: admin.role, status: :ok
    else
      render plain: "Not Found", status: :not_found
    end
  end
  def assignable
    AuthService.requires_access(@authenticated_account, 'commanders-manage')
    role_order = ["Wiki Team", "Trainee", "FC", "Instructor", "Leadership"]

    options = @authenticated_account.access.select { |scope| scope.include?("commanders-manage:") }.map { |scope| scope.split(":").last }

    options.sort! do |a, b|
      a_index = role_order.index(a)
      b_index = role_order.index(b)

      if a_index && b_index
        a_index <=> b_index
      else
        0
      end
    end

    render json: options, status: :ok
  end
  def list
    AuthService.requires_access(@authenticated_account, 'commanders-view')

    filters = Admin.group(:role).select(:role, 'COUNT(role) as member_count')

    filters = filters.map do |filter|
      {
        name: filter.role,
        member_count: filter.member_count
      }
    end

    rows = Admin.joins("INNER JOIN character AS fc ON fc.id = admin.character_id")
                .joins("INNER JOIN character AS a ON a.id = admin.granted_by_id")
                .select("admin.role, admin.granted_at, fc.id, fc.name, a.id AS admin_id, a.name AS admin_name")

    commanders = rows.map do |cmdr|
      {
        character: { id: cmdr.attributes['id'], name: cmdr.name },
        role: cmdr.role,
        granted_by: { id: cmdr.admin_id, name: cmdr.admin_name },
        granted_at: cmdr.granted_at
      }
    end

    if commanders.empty?
      render plain: "No Content", status: 204
    else
      render json: { commanders: commanders, filters: filters }, status: :ok
    end

  end

  def public_list
    commanders = Admin.joins(:character).where(role: ['Leadership', 'FC']).order(role: :asc).map { |c| { id: c.character.id, name: c.character.name, role: c.role } }
    render status: :ok, json: commanders
  end
end
