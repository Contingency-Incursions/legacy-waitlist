import React, { useMemo } from "react";
// import { useApi } from "../../api";
import { Input, InputGroup } from "../../Components/Form";
// import _ from "lodash";
import { Content } from "../../Components/Page";
// import { Cell, CellHead, Row, Table, TableBody, TableHead } from "../../Components/Table";
// import { formatDatetime, formatDuration } from "../../Util/time";
// import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
// import { faStar } from "@fortawesome/free-solid-svg-icons";
import { usePageTitle } from "../../Util/title";

export function FcStats() {
  const [date, setDate] = React.useState("");
  const [time, setTime] = React.useState("");
  const [end_date, setEndDate] = React.useState("");
  const [end_time, setEndTime] = React.useState("");

  const parsedDate = date && time ? new Date(`${date}T${time}Z`) : null;
  const parsedEndDate = useMemo(() => {
    return end_date && end_time ? new Date(`${end_date}T${end_time}Z`) : null;
  }, [end_date, end_time]);

  //const parsedDateUnix = parsedDate ? parsedDate.getTime() / 1000 : null;

  //const [result] = useApi(parsedDateUnix ? `/api/history/fleet-comp?time=${parsedDateUnix}` : null);

  usePageTitle("FC Stats");
  return (
    <Content>
      <h2>FC Stats</h2>
      <InputGroup>
        <Input type="date" value={date} onChange={(evt) => setDate(evt.target.value)} />
        <Input type="time" value={time} onChange={(evt) => setTime(evt.target.value)} />
      </InputGroup>
      {parsedDate ? (
        <div>
          <em>{parsedDate.toString()}</em>
        </div>
      ) : null}

      <InputGroup>
        <Input type="date" value={end_date} onChange={(evt) => setEndDate(evt.target.value)} />
        <Input type="time" value={end_time} onChange={(evt) => setEndTime(evt.target.value)} />
      </InputGroup>
      {parsedDate ? (
        <div>
          <em>{parsedEndDate.toString()}</em>
        </div>
      ) : null}

      {/* {result && <h2>Results</h2>}
      {result &&
        _.map(result.fleets, (comp, fleetId) => (
          <div key={fleetId}>
            <h3>Fleet {fleetId}</h3>
            <Table fullWidth>
              <TableHead>
                <Row>
                  <CellHead>Pilot</CellHead>
                  <CellHead>Ship</CellHead>
                  <CellHead>Time</CellHead>
                </Row>
              </TableHead>
              <TableBody>
                {comp.map((entry) => (
                  <Row key={entry.character.id}>
                    <Cell>
                      {entry.character.name}
                      {entry.is_boss && (
                        <>
                          {" "}
                          <FontAwesomeIcon icon={faStar} />
                        </>
                      )}
                    </Cell>
                    <Cell>{entry.hull.name}</Cell>
                    <Cell>
                      {formatDatetime(new Date(entry.logged_at * 1000))} (
                      {formatDuration(entry.time_in_fleet)})
                    </Cell>
                  </Row>
                ))}
              </TableBody>
            </Table>
          </div>
        ))}
      {result && _.isEmpty(result.fleets) && <em>Nothing found!</em>} */}
    </Content>
  );
}
