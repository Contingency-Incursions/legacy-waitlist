import A from "../../../Components/A";
import { Header } from "../../../Components/Page";
import { useApi } from "../../../api";
import { useMemo } from "react";
import Table from "../../../Components/DataTable";
import styled from "styled-components";

const DOM = styled.div`
  margin-bottom: 50px;
`;


const RecentFleets = () => {
  const [ recentFleets ] = useApi('/api/v2/fleets/history')

  const fleets = useMemo(() => {
    let _fleets = {}
    if(recentFleets === null){
      return _fleets;
    }
    recentFleets.fleets.forEach(fleet => {
      let existingEntry = _fleets[fleet.fleet_id];
      let id = fleet.fleet_id;
      if(existingEntry === undefined){
        _fleets[id] = {
          fleet_id: id,
          bosses: [fleet.character_name],
          total_time: fleet.fleet_time
        }
      } else {
        _fleets[id].bosses.push(fleet.character_name);
        _fleets[id].total_time += fleet.fleet_time
      }
    })
    return Object.values(_fleets);
  }, [recentFleets])

  return (
          <DOM>
            <Header>
              <h2>Recent Fleets</h2>
            </Header>
            New page coming soon. For now <A href="/fc/fleet/history">use this</A>!
            <Table
              columns={[
                { name: "Fleet ID", selector: (r) => r?.fleet_id },
                { name: "Bosses", selector: (r) => r?.bosses },
                { name: "Fleet Time", selector: (r) => (r?.total_time / 3600).toFixed(2) },
              ]}
              data={fleets ?? []}
              progressPending={!fleets}
              pagination={false}
            />
          </DOM>
  )
}

export default RecentFleets;
