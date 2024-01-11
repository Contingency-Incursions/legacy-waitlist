import styled from "styled-components";
import Account from "./AccountInformation";
import { WaitTime } from "./Timestamps";
import FitCard from "./FitCard";
import { useMemo } from "react";

const FlightstripDOM = styled.div`
  box-sizing: border-box;
  display: grid;
  grid-template-columns: repeat(5,minmax(0px,1fr));
  gap: 16px;
`;

const Fits = styled.div`
  display: grid;
  grid-column: span 3;
  grid-template-columns: repeat(2,minmax(0px,1fr));
  gap: 16px;

  @media (max-width: 1400px) {
    grid-template-columns: repeat(1,minmax(0px,1fr));
  }
`;

const Flightstrip = ({ id, character, fleet_time, fits, joined_at, bossId, tab, inviteCounts, setInviteCounts, skills, setSkills, max_alts }) => {
  let show = useMemo(() => {
    if(!fits) return false;
    if(tab == 'All'){
      return fits.length > 0;
    }
    if(tab == 'Alts') {
      return fits.filter(fit => fit.is_alt === true).length > 0;
    } else {
      return fits.filter(fit => fit.category === tab).length > 0;
    }
  },
  [fits, tab])

  const tags = useMemo(() => {
    return [...new Set(fits.map(fit => fit.tags).reduce((a, b) => a.concat(b), []))];
  }, [fits])

  return (
    <FlightstripDOM style={{display: show ? 'grid': 'none'}}>
      <Account 
      {...character} 
      fleet_time={fleet_time} 
      bastion_x={fits.filter(fit => fit.hull.name == "Paladin" || fit.hull.name == "Kronos" || fit.hull.name == 'Vargur').length > 0} 
      tags={tags}
      />

      <WaitTime joined_at={joined_at} />

      <Fits>
        {fits?.map((fit) => <FitCard 
        fit={fit} 
        max_alts={max_alts}
        bossId={bossId} 
        key={fit.id} 
        tab={tab} 
        inviteCounts={inviteCounts} 
        onInvite={setInviteCounts}/> )}
      </Fits>
    </FlightstripDOM>
  )
}

export default Flightstrip;
