import { useState, useMemo } from "react";
import styled from "styled-components";
import Navs from "./Waitlist/Navs";
import Spinner from "../../../Components/Spinner";
import Flightstrip from "./Waitlist/FlightStrip";
import { useApi } from "../../../api";

const WaitlistDOM = styled.div`
  border-top: 1px solid ${(props) => props.theme.colors.accent1};
  padding-top: 10px;
`;

const Waitlist = ({ fleetId, xup }) => {
  const [ tab, selectTab ] = useState('All');
  const [ settings ] = useApi(`/api/v2/fleets/${fleetId}`);

  let bossId = useMemo(() => {
    return settings?.boss?.id;
  }, [settings])

  
  let filteredFits = useMemo(() => {
    if(!xup) return [];
    if(!xup.waitlist) return [];
    if(tab == 'All'){
      return xup?.waitlist;
    }
    let fits_filtered = structuredClone(xup.waitlist);
    fits_filtered = fits_filtered.map(account => {
      account.fits = account.fits.filter(fit => fit.category === tab)
      return account
    })
    return fits_filtered.filter(account => account.fits.length > 0);
  },
  [xup, tab])

  let fits = useMemo(() => {
    if(!xup) return [];
    if(!xup.waitlist) return [];
    let all_fits = xup?.waitlist?.map(waitlist => waitlist.fits);
    return [].concat(...all_fits);
  },
  [xup])

  if (!xup) {
    return (
      <WaitlistDOM style={{ textAlign: 'center' }}>
        <Spinner />
      </WaitlistDOM>
    )
  }

  return  (
    <WaitlistDOM>
      <Navs categories={xup?.categories} tab={tab} onClick={selectTab} fits={fits} />
      {filteredFits?.map((waitlist, key) =>       <Flightstrip {...waitlist} bossId={bossId} key={key} />)}
    </WaitlistDOM>
  )
}

export default Waitlist;
