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

    const comp_updated = (e) => {
      let data = e.data;
      if (data.id === fleetId) {
        refreshPilots();
      }
    }

    let sub = null;

    if(fleetId){
      sub = eventContext.subscriptions.create({channel: 'FcChannel'}, {
        received(data){
          comp_updated(data);
        }
      })
    }


    return () => {
      if(sub !== null){
        sub.unsubscribe();
      }
    }
  }, [eventContext, fleetId, refreshPilots])

  let characters = useMemo(() => {
    let _characters = []
    if (pilots !== null) {
      _characters = pilots.filter(p => p.characters.length > 1);
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
        Fleet Multibox Payouts
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
