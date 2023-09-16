import { useContext } from "react";
import { AuthContext } from "../../../contexts";
import { useApi } from "../../../api";

import { AButton, Buttons } from "../../../Components/Form";
import { Badge } from "../../../Components/Badge";
import { CharacterName } from "../../../Components/EntityLinks";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCog, faEye, faEyeSlash } from "@fortawesome/free-solid-svg-icons";
import { Header } from "../../../Components/Page";
import RecentFleets from "./RecentFleets";
import Table from "../../../Components/DataTable";
import styled from "styled-components";
import { usePageTitle } from "../../../Util/title";
import CloseAllBtn from "./CloseAllButton";
import RegisterFleetBtn from "./Register";

const DOM = styled.div`
  margin-bottom: 50px;
`;


const FleetSize = ({ size = '-', size_max = '-' }) => {
  return <>soon&trade;</>
  // let count = `${size} / ${size_max}`;

  // if (size > size_max) {
  //   count = (
  //     <Badge variant='warning' data-tooltip-id="tip" data-tooltip-html="Fleet overgrid">
  //       {count}
  //     </Badge>
  //   )
  // }

  // return count;
}

const FleetStatus = ({ is_listed = false }) => {
  return (
    <Badge variant={is_listed ? 'success' : 'danger'}>
      <FontAwesomeIcon fixedWidth icon={ is_listed ? faEye : faEyeSlash } />
      &nbsp; { is_listed ? 'Listed' : 'Not-Listed' }
    </Badge>
  )
}


const FleetsIndexPage = () => {
  const authContext = useContext(AuthContext);
  const [ data, refresh ] = useApi('/api/v2/fleets')

  usePageTitle('Fleets')

  return (
    <>
      <DOM>
        <Header>
          <h1>Active Fleets</h1>
          <Buttons>
            <RegisterFleetBtn refreshFunction={refresh} />
            <CloseAllBtn refreshFunction={refresh} />
          </Buttons>
        </Header>

        <Table
          columns={[
            { name: "Fleet Boss", selector: (r) => <CharacterName {...r?.boss} /> },
            { name: "Status", selector: (r) => <FleetStatus {...r} /> },
            { name: "Size", selector: (r) => <FleetSize {...r} /> },
            { name: "System", selector: (r) => <>soon&trade;</> },
            {
              name: "", selector: (r) => (
                <AButton href={`/fc/fleets/${r.id}`}>
                  <FontAwesomeIcon fixedWidth icon={faCog} /> Manage
                </AButton>
              )
            }
          ]}
          data={data ?? []}
          progressPending={!data}
          pagination={false}
        />
      </DOM>

      {authContext?.access['fleet-history-view'] && <RecentFleets />}
    </>
  );
}

export default FleetsIndexPage;
