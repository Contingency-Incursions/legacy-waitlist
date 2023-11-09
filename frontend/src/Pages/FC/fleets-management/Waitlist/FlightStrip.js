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

const Flightstrip = ({ id, character, fits, joined_at, bossId, tab }) => {
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

  let fleet_time = useMemo(() => {
    let time = 0;
    fits.forEach((fit) => {
      if(fit.hours_in_fleet > time){
        time = fit.hours_in_fleet;
      }
    })
    return time;
  })
  return (
    <FlightstripDOM style={{display: show ? 'grid': 'none'}}>
      <Account {...character} fleet_time={fleet_time} />

      <WaitTime joined_at={joined_at} />

      <Fits>
        {fits?.map((fit) => <FitCard fit={fit} bossId={bossId} key={fit.id} tab={tab} /> )}
      </Fits>
    </FlightstripDOM>
  )
}

export default Flightstrip;
