import { useState, useMemo, useCallback } from "react";
import styled from "styled-components";
import Navs from "./Waitlist/Navs";
import Spinner from "../../../Components/Spinner";
import Flightstrip from "./Waitlist/FlightStrip";

const WaitlistDOM = styled.div`
  border-top: 1px solid ${(props) => props.theme.colors.accent1};
  padding-top: 10px;
`;

const Waitlist = ({ fleetId, xup, settings }) => {
  const [tab, setTab] = useState("All");
  const [inviteCounts, setInviteCounts] = useState({});
  const [skills, setSkills] = useState({});

  let bossId = useMemo(() => {
    return settings?.boss?.id;
  }, [settings]);

  let fits = useMemo(() => {
    if (!xup) return [];
    if (!xup.waitlist) return [];
    let all_fits = xup?.waitlist?.map((waitlist) => waitlist.fits);
    return [].concat(...all_fits);
  }, [xup]);

  const handleSelect = useCallback((evt) => {
    setTab(evt);
  }, []);

  if (!xup) {
    return (
      <WaitlistDOM style={{ textAlign: "center" }}>
        <Spinner />
      </WaitlistDOM>
    );
  }
  return (
    <WaitlistDOM>
      <Navs categories={xup?.categories} tab={tab} onClick={handleSelect} fits={fits} />
      {xup?.waitlist?.map((waitlist) => (
        <Flightstrip
          {...waitlist}
          bossId={bossId}
          key={waitlist.id}
          tab={tab}
          inviteCounts={inviteCounts}
          setInviteCounts={setInviteCounts}
          skills={skills}
          setSkills={setSkills}
        />
      ))}
    </WaitlistDOM>
  );
};

export default Waitlist;
