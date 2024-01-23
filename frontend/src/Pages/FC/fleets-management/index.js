import { useContext, useEffect } from 'react';
import { useApi } from '../../../api';
import { useParams } from 'react-router-dom';
import { FireNotificationApi } from '../../../Components/Event';


import FleetSettings from './Settings';
import FleetComps from './FleetComps';
import Waitlist from './Waitlist';
import Payouts from './Payouts';
import { EventContext } from '../../../contexts';

const FleetsManagementPage = () => {
  const eventContext = useContext(EventContext);
  const url = useParams();
  const [ xup, refresh ] = useApi(`/api/v2/fleets/${url?.fleetId}/waitlist`);
  const [ settings, settingsRefresh ] = useApi(`/api/v2/fleets/${url?.fleetId}`);


  useEffect(() => {
    if (!eventContext) return;

    
    const waitlist_sub = eventContext.subscriptions.create({channel: 'WaitlistChannel'}, {
      received(data){
        refresh(data);
      }
    })

    const fc_sub = eventContext.subscriptions.create({channel: 'FcChannel'}, {
      received(data){
        if(data.event == 'notification'){
          let event_data = data?.data;
          if (!event_data) return;
        
          FireNotificationApi({
            title: event_data?.title,
            body: event_data.message,
          });
        }
      }
    })

    return () => {
      waitlist_sub.unsubscribe();
      fc_sub.unsubscribe();
    }
  }, [eventContext, refresh])
  return (
    <>
      <FleetSettings fleetId={url?.fleetId} xups={xup?.waitlist} settings={settings} settingsRefresh={settingsRefresh} />
      <FleetComps fleetId={url?.fleetId} />
      <Payouts fleetId={url?.fleetId} />
      <Waitlist xup={xup} settings={settings} />
    </>
  )
}

export default FleetsManagementPage;
