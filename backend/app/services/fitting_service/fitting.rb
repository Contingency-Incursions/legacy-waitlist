# frozen_string_literal: true

module FittingService
  class Fitting
    FitError = Class.new(StandardError)

    class << self
      def from_eft(eft)
        fittings = []
        section = 0
        stripped_lines = eft.strip.lines.map(&:strip)
        section_counts = []
        names_to_retrieve = []
        modules = []

        stripped_lines.each_with_index do |line, i|
          if line.start_with?('[') && line.end_with?(']') && line.include?(',')
            hull_name, ship_name = parse_hull_and_ship(line)
            fitting = { hull: nil, hull_name: nil, cargo: {}, modules: {} }
            fitting[:hull_name] = hull_name

            raise FitError, 'Parse Error' if ship_name.nil?

            names_to_retrieve << hull_name
            section = 0
            fittings << fitting
            modules << []
            section_counts << 0
          else
            mods = modules.last
            next if line.start_with?("[Empty ")
            if line.blank?
              next if stripped_lines[i+1].start_with?('[') && stripped_lines[i+1].end_with?(']') && stripped_lines[i+1].include?(',')
              section_counts[-1] += 1
              section += 1
              next
            end
            type_name, count, stacked = parse_line(line)

            mods << [type_name, count, stacked, section]
            names_to_retrieve << type_name
          end
        end

        types = InvTypesService.load_types_from_names(names_to_retrieve, include_groups: true).to_a



        modules.each_with_index do |mods, i|
          fitting = fittings[i]
          fitting[:hull] = types.select { |t| t.typeName == fitting[:hull_name] }[0]&.typeID
          mods.each do |mod|
            type = types.select { |t| t.typeName == mod[0] }[0]
            is_cargo = cargo?(mod[3], section_counts[i], type, mod[2])

            add_item_to_fitting(fitting, type&.typeID, mod[1], is_cargo)
          end

        end

        fittings
      end

      def from_dna(dna)
        pieces = dna.split(':')
        hull = pieces.first.to_i # assumes the first element of dna is an integer

        line_data = pieces[1..-1].map do |piece|
          next if piece.empty?
          type_id, count_str = piece.split(';', 2)
          type_id = type_id.chomp('_').to_i
          count = count_str ? count_str.to_i : 1
          is_cargo = piece.end_with?('_')
          [type_id, count, is_cargo]
        end.compact

        type_ids = line_data.map { |type, _, _| type }
        db_types = InvTypesService.load_types(type_ids, with_groups: true)

        modules, cargo = line_data.each_with_object([Hash.new(0), Hash.new(0)]) do |(type_id, count, is_cargo), (modules, cargo)|
          is_cargo ||= db_types[type_id]&.is_always_cargo
          if is_cargo
            cargo[type_id] += count
          else
            modules[type_id] += count
          end
        end

        { hull: hull, modules: modules, cargo: cargo }
      rescue => e
        raise FitError, "Parse error: #{e.message}"
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
