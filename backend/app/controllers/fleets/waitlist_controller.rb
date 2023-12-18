# frozen_string_literal: true

module Fleets
  class WaitlistController < ApplicationController
    def fleet_waitlist
      AuthService.requires_access(@authenticated_account, 'fleet-view')

      waitlist_categories = CategoriesData.categories.map {|c| c['name']}
      waitlist_category_lookup = {}
      CategoriesData.categories.each {|c| waitlist_category_lookup[c['id']] = c['name']}

      records = ActiveRecord::Base.connection.execute(        "
            SELECT
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
            ORDER BY we.id ASC, wef.id ASC
        ")

      hulls = records.map { |record| record['fitting_hull'] }.uniq
      hull_names = InvTypesService.names_of(hulls)

      entries = {}
      records.each do |r|
        record = r.with_indifferent_access
        x_is_ours = record[:we_account_id] == @authenticated_account.id

        unless entries[record[:we_id]].present?
          entries[record[:we_id]] = {
            id: record[:we_id],
            fits: [],
            character: (x_is_ours || @authenticated_account.access.include?("waitlist-view")) ?
                         { id: record[:char_we_id], name: record[:char_we_name] } : nil,
            joined_at: record[:we_joined_at],
            can_remove: x_is_ours || @authenticated_account.access.include?("waitlist-manage"),
            fleet_time: Waitlist::XupService.get_time_in_fleet(record[:char_we_id])
          }
        end

        entry = entries[record[:we_id]]

        this_fit = {
          id: record[:wef_id],
          approved: record[:wef_state] == 'Approved',
          state: record[:wef_state],
          category: waitlist_category_lookup[record[:wef_category]],
          tags: [],
          hull: {
            id: record[:fitting_hull],
            name: hull_names[record[:fitting_hull]]
          },
          character: nil,
          hours_in_fleet: nil,
          review_comment: nil,
          dna: nil,
          implants: nil,
          fit_analysis: nil,
          is_alt: record[:wef_is_alt]
        }

        tags = record[:wef_tags].split(',').compact

        if x_is_ours or @authenticated_account.access.include?('waitlist-view')
          this_fit[:character] = {
            id: record[:char_wef_id],
            name: record[:char_wef_name]
          }
          this_fit[:hours_in_fleet] = record[:wef_cached_time_in_fleet] / 3600
          this_fit[:review_comment] = record[:wef_review_comment]
          this_fit[:tags] = tags
        else
          this_fit[:tags] = tags.filter {|tag| TagsData::PUBLIC_TAGS.include?(tag)}
        end

        if x_is_ours or (@authenticated_account.access.include?('waitlist-view') and @authenticated_account.access.include?('fit-view'))
          this_fit[:dna] = record[:fitting_dna]
          this_fit[:implants] = record[:implant_set_implants].split(':').compact.map(&:to_i)
          this_fit[:fit_analysis] = Hash[*JSON.parse(record[:wef_fit_analysis].gsub('\"', '"').gsub('"[', '[').gsub(']"', ']')).flatten(1)]
        end

        entry[:fits] << this_fit
      end
      # remaining transformations of records to entries go here, as per Rust code

      render json: { open: true, waitlist: entries.values, categories: waitlist_categories }
    end

    private


  end
end
