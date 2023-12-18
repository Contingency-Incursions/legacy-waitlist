module Authentication
  extend ActiveSupport::Concern

  private

  def get_current_account
    account_id = cookies.permanent.encrypted[:current_user_id]

    if account_id.blank?
      return nil
    end

    # If the admin table has a character_id field
    access_level_record = Admin.find_by(character_id: account_id)

    # If instead it has an account_id or user_id or some other field
    # access_level_record = Admin.find_by(account_id: account_id)

    access_level = access_level_record ? access_level_record.role : "user"

    access_keys = AuthService.build_access_levels[access_level]

    if access_keys.blank?
      return nil
    end

    @authenticated_account = AuthenticatedAccount.new(
      id: account_id,
      access: access_keys,
      )
  end

  def authenticate!
    account_id = cookies.permanent.encrypted[:current_user_id]

    if account_id.blank?
      render json: { error: 'Missing token cookie' }, status: :unauthorized
      return
    end

    # If the admin table has a character_id field
    access_level_record = Admin.find_by(character_id: account_id)

    # If instead it has an account_id or user_id or some other field
    # access_level_record = Admin.find_by(account_id: account_id)

    access_level = access_level_record ? access_level_record.role : "user"

    access_keys = AuthService.build_access_levels[access_level]

    if access_keys.blank?
      render json: { error: 'Invalid access level' }, status: :unauthorized
      return
    end

    @authenticated_account = AuthenticatedAccount.new(
      id: account_id,
      access: access_keys,
      )
  end

  def authorize_character!(char_id, permission_override)
    if @authenticated_account.id == char_id
      return true
    end

    if permission_override.present? and @authenticated_account.access.include?(permission_override)
      return true
    end

    alt_char = AltCharacter.where(account_id: @authenticated_account.id, alt_id: char_id)

    if alt_char.first.present?
      true
    else
      false
    end

  end



end
