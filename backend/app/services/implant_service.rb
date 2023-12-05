# frozen_string_literal: true

class ImplantService
  class << self
    def detect_base_set(implants)
      set_implants = [
        [
          "AMULET",
          [20499, # High-grade Amulet Alpha
           20501, # High-grade Amulet Beta
           20503, # High-grade Amulet Delta
           20505, # High-grade Amulet Epsilon
           20507, # High-grade Amulet Gamma
           3119], # WS-618
        ],
        [
          "WARPSPEED",
          [33516, # High-grade Ascendancy Alpha
           33525, # High-grade Ascendancy Beta
           33526, # High-grade Ascendancy Delta
           33527, # High-grade Ascendancy Epsilon
           33528, # High-grade Ascendancy Gamma
           33529], # High-grade Ascendancy Omega
        ],
        [
          "WARPSPEED",
          [33516, # High-grade Ascendancy Alpha
           33525, # High-grade Ascendancy Beta
           33526, # High-grade Ascendancy Delta
           33527, # High-grade Ascendancy Epsilon
           33528, # High-grade Ascendancy Gamma
           3119], # WS-618
        ],
        [
          "SAVIOR",
          [53890, # High-grade Savior Alpha
           53891, # High-grade Savior Beta
           53893, # High-grade Savior Delta
           53894, # High-grade Savior Epsilon
           53892, # High-grade Savior Gamma
           53895], # High-grade Savior Omega
        ]
      ]

      set_implants.each do |set|
        setname = set[0]
        set_implants = set[1]
        return setname if set_implants.all? { |id| implants.include?(id) }
      end

      nil
    end

    def detect_slot7(hull, implants)
      return if implants.include?(20443) || # Ogdin's Eye Coordination Enhancer
        implants.include?(3192) || # % MR-706
        (hull == 33472 || hull == 11989) && implants.include?(3470) # Nestor, Oneiros, RA-706

      nil
    end

    def detect_slot8(hull, implants)
      return if implants.include?(3239) || # EM-806
        (implants.include?(24663) || # Zor's Custom Navigation Hyper-Link
          implants.include?(47263)) && #  MR-807
          !(hull == 33472 || hull == 11989) # Nestor, Oneiros

      nil
    end

    def detect_slot9(hull, implants)
      if hull == 33472 || hull == 11989 # Nestor, Oneiros
        true
      elsif implants.include?(3214) || # RF-906
        implants.include?(3195) || # SS-906
        implants.include?(25868) # Pashan's Turret Customization Mindlink
        return true
      else
        nil
      end
    end

    def detect_slot10(hull, implants)
      if hull == 17736 || hull == 28659 # Nightmare, Paladin
        (implants.include?(25867) || # Pashan's Turret Handling Mindlink
          implants.include?(3215)) ? true : nil # LE-1006
      elsif hull == 17740 || hull == 28661 # Vindicator, Kronos
        return (implants.include?(3224)) ? true : nil # LH-1006
      else
        true
      end
    end

    def detect_set(hull, implants)
      base_set = detect_base_set(implants)
      return nil if base_set.nil?
      return nil if detect_slot7(hull, implants).nil?
      return nil if detect_slot8(hull, implants).nil?
      return nil if detect_slot9(hull, implants).nil?

      base_set
    end
  end
end
