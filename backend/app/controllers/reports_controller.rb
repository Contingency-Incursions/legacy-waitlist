# frozen_string_literal: true

class ReportsController < ApplicationController
  def index
    AuthService.requires_access(@authenticated_account, 'reports-view')

    activity = ActiveRecord::Base.connection.execute("
      SELECT
        c.id AS id,
        c.id AS character_id,
        c.name AS name,
        'Fleet Boss' AS role, 
        MAX(fa.last_seen) AS last_seen, 
        SUM(fa.last_seen - fa.first_seen) AS seconds_last_month
      FROM character AS c
        JOIN admin AS a on a.character_id = c.id
        LEFT JOIN fleet_activity AS fa
        ON fa.character_id = c.id AND fa.is_boss = 'true' AND (fa.last_seen - fa.first_seen) > 300
      GROUP BY
        c.id,
        c.name
      UNION
      SELECT
        -1 * c.id AS id, 
        c.id as character_id,
        c.name as name,
       'Logi' AS role,
        max(fa.last_seen) as last_seen,
        SUM(fa.last_seen - fa.first_seen) AS seconds_last_month
      FROM character AS c
        JOIN badge_assignment AS ba ON ba.characterId = c.id
        JOIN badge AS b ON b.id = ba.badgeID AND b.name = 'LOGI'
        LEFT JOIN fleet_activity AS fa
        ON fa.character_id = c.id AND (fa.hull=33472 OR fa.hull=11989) AND (fa.last_seen - fa.first_seen) > 300
      GROUP BY c.id, c.name") # Nestor, Oni

    render json: activity.as_json
  rescue => e
    render plain: e.message, status: :internal_server_error
  end
end
