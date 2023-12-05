# frozen_string_literal: true

class WaitlistController < ApplicationController

  def index
    account = @authenticated_account

      begin
        waitlist_categories = CategoriesData.categories.map { |cat| cat['name'] }
        waitlist_categories_lookup = CategoriesData.categories.map { |cat| [cat['id'], cat['name']] }.to_h

        visible_fleets = Fleet.where(visible: true).pluck(:id)

        if visible_fleets.empty?
          return render json: {
            open: false,
            waitlist: nil,
            categories: waitlist_categories
          }
        end

        raise NotImplementedError

        records = app.execute_query(
          "SELECT
          we.id we_id,
          we.joined_at we_joined_at,
          we.account_id we_account_id,
          wef.id wef_id,
          wef.state wef_state,
          wef.category wef_category,
          wef.cached_time_in_fleet wef_cached_time_in_fleet,
          wef.review_comment wef_review_comment,
          wef.tags wef_tags,
          wef.fit_analysis wef_fit_analysis,
          wef.is_alt wef_is_alt,
          char_wef.id char_wef_id,
          char_wef.name char_wef_name,
          char_we.id char_we_id,
          char_we.name char_we_name,
          fitting.dna fitting_dna,
          fitting.hull fitting_hull,
          implant_set.implants implant_set_implants
          FROM waitlist_entry_fit wef
          JOIN waitlist_entry we ON wef.entry_id = we.id
          JOIN character char_wef ON wef.character_id = char_wef.id
          JOIN character char_we ON we.account_id = char_we.id
          JOIN fitting ON wef.fit_id = fitting.id
          JOIN implant_set ON wef.implant_set_id = implant_set.id
          ORDER BY we.id ASC, wef.id ASC"
        )

        # Your task here is to provide equivalent data conversion methods in Rails
        hulls = records.map { |r| r.fitting_hull }.uniq
        hull_names = # Assume you have similar method to TypeDB::names_of

          entries = {}
        records.each do |record|
          x_is_ours = record.we_account_id == account.id

          entry = entries[record.we_id] ||= WaitlistEntry.new(# Assuming WaitlistEntry is a model
            # equivalent properties assignment here
          )

          # From this point on, make sure you create an equivalent WaitlistEntryFit model in Rails
          # and conversion of data from the fetched rows
        end

        render json: {
          open: true,
          categories: waitlist_categories,
          waitlist: entries.values
        }
      # rescue => e
      #   # Equivalent to Result::Err, handle error here
      #   render json: { error: e.message }, status: :internal_server_error
      end
  end
end
