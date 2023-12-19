import { useContext, useEffect } from 'react';
import { useApi } from '../../../api';
import { useParams } from 'react-router-dom';


import FleetSettings from './Settings';
import FleetComps from './FleetComps';
import Waitlist from './Waitlist';
import { EventContext } from '../../../contexts';

const FleetsManagementPage = () => {
  const eventContext = useContext(EventContext);
  const url = useParams();
  const [ xup, refresh ] = useApi(`/api/v2/fleets/${url?.fleetId}/waitlist`);
  const [ settings, settingsRefresh ] = useApi(`/api/v2/fleets/${url?.fleetId}`);


  useEffect(() => {
    if (!eventContext) return;

    eventContext.addEventListener("waitlist_update", refresh);
    return () => eventContext.removeEventListener("waitlist_update", refresh);
  }, [eventContext, refresh])
  return (
    <>
      <FleetSettings fleetId={url?.fleetId} xups={xup?.waitlist} settings={settings} settingsRefresh={settingsRefresh} />
      <FleetComps fleetId={url?.fleetId} />
      <Waitlist xup={xup} settings={settings} />
    </>
  )
}

export default FleetsManagementPage;
