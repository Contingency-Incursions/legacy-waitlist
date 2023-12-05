# frozen_string_literal: true

module FittingService
  class Fitting
    FitError = Class.new(StandardError)

    class << self
      def from_eft(eft)
        fitting = { hull: nil, hull_name: nil, cargo: {}, modules: {} }
        section = 0
        stripped_lines = eft.strip.lines.map(&:strip)
        section_count = stripped_lines.filter(&:blank?).count
        names_to_retrieve = []
        modules = []

        stripped_lines.each do |line|
          if line.start_with?('[') && line.end_with?(']') && line.include?(',')
            hull_name, ship_name = parse_hull_and_ship(line)
            fitting[:hull_name] = hull_name

            raise FitError, 'Parse Error' if ship_name.nil?

            names_to_retrieve << hull_name
            section = 0
          else
            next if line.start_with?("[Empty ")
            if line.blank?
              section += 1
              next
            end
            type_name, count, stacked = parse_line(line)

            modules << [type_name, count, stacked, section]
            names_to_retrieve << type_name
          end
        end

        types = InvTypesService.load_types_from_names(names_to_retrieve, include_groups: true).to_a

        fitting[:hull] = types.select { |t| t.typeName == names_to_retrieve[0] }[0]&.typeID

        modules.each do |mod|
          type = types.select { |t| t.typeName == mod[0] }[0]
          is_cargo = cargo?(mod[3], section_count, type, mod[2])

          add_item_to_fitting(fitting, type&.typeID, mod[1], is_cargo)
        end

        fitting
      end

      def from_dna(dna)
        pieces = dna.split(':')
        hull = pieces.first.to_i # assumes the first element of dna is an integer
        modules = Hash.new(0)
        cargo = Hash.new(0)

        lines = []
        pieces[1..-1].each do |piece|
          next if piece.empty?

          type_id_str, count_str = piece.split(';', 2)
          type_id = type_id_str.chomp('_').to_i

          count = count_str ? count_str.to_i : 1

          lines << [type_id, count, type_id_str]
        end

        db_types = InvTypesService.load_types(lines.map{|l| l[0]}, with_groups: true)

        lines.each do |line|
          is_cargo = if line[2].end_with?('_')
                       true
                     else
                       loaded_type = db_types[line[0]]
                       loaded_type&.is_always_cargo
                     end

          if is_cargo
            cargo[line[0]] += line[1]
          else
            modules[line[0]] += line[1]
          end
        end


        { hull: hull, modules: modules, cargo: cargo }
        # Assuming that the Fitting model has attributes :hull, :modules, :cargo
      rescue => e
        raise FitError, "Parse error: #{e.message}"
        # Assuming FitError is a defined error you want to raise in case of error
      end

      def to_dna(fit)
        hull = fit[:hull]
        modules = fit[:modules]
        cargo = fit[:cargo]
        dna = "#{hull}:"

        modules.each do |id, count|
          dna += "#{id};#{count}:"
        end

        types = InvTypesService.load_types(cargo.keys, with_groups: true)

        cargo.each do |id, count|
          inv_type = types.find {|type| type[0] == id}[1]
          return nil unless inv_type # error loading type

          if inv_type.is_always_cargo
            dna += "#{id};#{count}:"
          else
            dna += "#{id}_;#{count}:"
          end
        end

        dna + ":"
      end

      private

      def parse_hull_and_ship(line)
        stripped_line = line.gsub(/^\[/, '').gsub(/\]$/, '')
        parts = stripped_line.split(',', 2)
        [parts[0].strip, parts[1]] # Returns (hull_name, ship_name)
      end

      def parse_line(line)
        parts = line.split(" x")
        type_name = parts[0].strip
        count, stacked = determine_stack_and_count(parts[1])
        [type_name, count, stacked] # Returns (type_name, count, stacked)
      end

      def cargo?(section, section_count, type, stacked)
        !(section < section_count && (type.inv_group.groupName != 'Drone' || !stacked))
      end

      def add_item_to_fitting(fitting, type_id, count, is_cargo)
        if is_cargo
          fitting[:cargo][type_id] ||= 0
          fitting[:cargo][type_id] += count
        else
          fitting[:modules][type_id] ||= 0
          fitting[:modules][type_id] += count
        end
      end

      def determine_stack_and_count(count_data)
        if count_data.present?
          [count_data.to_i, true]
        else
          [1, false]
        end
      end
    end
  end
end
