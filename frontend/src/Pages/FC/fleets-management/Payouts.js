/* eslint-disable eqeqeq */
import { useContext, useEffect, useMemo } from "react";
import { useApi } from "../../../api";
import styled from "styled-components";
import { EventContext } from "../../../contexts";
import Pilot from "./Payouts/Pilot";


const PilotContainerDom = styled.div`
  display: flex;
  flex-direction: row;
  min-height: 93px;
  // justify-content: center;
`;


const Payouts = ({ fleetId }) => {
  const eventContext = useContext(EventContext);
  // let [ fleets, refresh ] = useApi(`/api/v2/fleets`);
  const [pilots, refreshPilots] = useApi(`/api/v2/fleets/${fleetId}/payouts`);

  useEffect(() => {
    if (!eventContext) return;

    const sub = eventContext.subscriptions.create({ channel: 'FleetChannel' }, {
      received(data) {
        // refresh(data);
        refreshPilots(data);
      }
    })

    return () => {
      sub.unsubscribe();
    }
  }, [refreshPilots, eventContext])

  let characters = useMemo(() => {
    let _characters = []
    if (pilots !== null) {
      _characters = pilots;
    }
    _characters = _characters.sort((a, b) => {
      if (a.characters.length > b.characters.length) return -1;
      if (b.characters.length > a.characters.length) return 1;
      return a.main.name.localeCompare(b.main.name);
    });
    return _characters;
  }, [pilots])


  return (
    <div>
      <strong>
        Fleet Payouts
      </strong>
      <PilotContainerDom>
        {characters.map((pilot, key) => {
          return <Pilot
            character={pilot}
            key={key}
          />
        })}
      </PilotContainerDom>
    </div>
  )
}

export default Payouts;
