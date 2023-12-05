class SdeUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    FileUtils.mkdir_p("#{Dir.tmpdir}/sde_extract")
    InvType.transaction do
      download_unzip_exec_sql('invTypes', InvType, 'https://www.fuzzwork.co.uk/dump/latest/invTypes.csv')
      download_unzip_exec_sql('invGroups', InvGroup, 'https://www.fuzzwork.co.uk/dump/latest/invGroups.csv')
      download_unzip_exec_sql('invMetaTypes', InvMetaType, 'https://www.fuzzwork.co.uk/dump/latest/invMetaTypes.csv')
      download_unzip_exec_sql('dgmTypeAttributes', DgmTypeAttribute, 'https://www.fuzzwork.co.uk/dump/latest/dgmTypeAttributes.csv')
      download_unzip_exec_sql('dgmTypeEffects', DgmTypeEffect, 'https://www.fuzzwork.co.uk/dump/latest/dgmTypeEffects.csv')
      download_unzip_exec_sql('mapSolarSystems', MapSolarSystem, 'https://www.fuzzwork.co.uk/dump/latest/mapSolarSystems.csv')
    end
  end

  private

  def download_unzip_exec_sql(file, table, url)
    filename_csv = "#{Dir.tmpdir}/sde_extract/#{file}.csv"

    # Download the .bz2 file
    File.open(filename_csv, 'wb') do |fo|
      fo.write Net::HTTP.get(URI.parse(url))
    end

    table.delete_all
    ActiveRecord::Base.transaction do
      CSV.open(filename_csv, headers: true).each_slice(250) do |rows|
        table.insert_all(rows.map(&:to_h))
      end
    end
    File.delete(filename_csv) rescue nil
  end
end
