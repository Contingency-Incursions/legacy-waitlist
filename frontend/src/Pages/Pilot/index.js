import React from "react";
import { useLocation } from "react-router-dom";

import { AuthContext, ToastContext } from "../../contexts";
import { apiCall, errorToaster, useApi } from "../../api";
import { usePageTitle } from "../../Util/title";

import AltCharacters from "./AltCharacters";
import CommanderModal from "../FC/commanders/CommanderModal";
import CharacterBadgeModal from "../FC/badges/CharacterBadgeModal";
import BadgeIcon, { icons } from "../../Components/Badge";
import styled from "styled-components";
import WikiPassword from "../FC/WikiPassword";

import { AccountBannedBanner } from "../FC/bans/AccountBanned";
import { ActivitySummary } from "./ActivitySummary";
import { Button, InputGroup, NavButton } from "../../Components/Form";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faBan, faClipboard, faExternalLinkAlt, faGraduationCap, faPen, faPlane, faTimes } from "@fortawesome/free-solid-svg-icons";
import { Title, Content } from "../../Components/Page";
import { PilotHistory } from "./PilotHistory";
import { Row, Col } from "react-awesome-styled-grid";
import _ from "lodash";
import UnlinkChar from "./UnlinkChar";

const ControlButtons = styled.div`
  margin-top: 35px;
  margin-bottom: 35px;
  border: solid 3px ${(props) => props.theme.colors.secondary.accent};
  border-radius: 5px;

  :has(.buttons:empty){
    display: none;
  }

  div:first-of-type {
    background: ${(props) => props.theme.colors.secondary.accent};
    padding: 10px;
    border-radius: 5px;
    border-bottom-right-radius: 0px;
    border-bottom-left-radius: 0px;
    font-weight: bold;
    text-align: center;

    & + div {
      padding: 10px;
      padding-bottom: 0px;
    }
  }

  button, a[href="/auth/start/fc"] {
    display: block;
    margin-bottom: 12px;
    width: 100%;
  }
`;

const FilterButtons = styled.span`
  font-size: 0.75em;
  margin-left: 2em;

  a {
    cursor: pointer;
    padding: 0 0.2em;
  }
`;

async function OpenWindow(target_id, character_id) {
  return await apiCall(`/api/open_window`, {
    json: { target_id, character_id },
  });
}

function PilotTags({ tags }) {
  var tagImages = [];
  _.forEach(tags, (tag) => {
    if (tag in icons) {
      tagImages.push(
        <div key={tag} style={{ marginRight: "0.2em" }}>
          <BadgeIcon type={tag} height="40px" />
        </div>
      );
    }
  });
  return (
    <div style={{ display: "flex", marginBottom: "0.6em", flexWrap: "wrap" }}>{tagImages}</div>
  );
}

export function Pilot() {
  const authContext = React.useContext(AuthContext);
  if (!authContext) {
    return (
      <Content>
        <b>Login Required!</b>
        <p>
          This page will let you see your own CI Fleet statistics like x-up&apos;s, fleet times and
          skill changes.
        </p>
      </Content>
    );
  }
  return <PilotDisplay authContext={authContext} />;
}

const PageMast = styled.div`
  display: flex;
  align-items: center;
  padding-bottom: 30px;

  @media (max-width: 400px) {
    flex-direction: column;
  }

  img {
    border-radius: 50%;
    height: 100px;
    width: 100px;
    margin-right: 10px;
    vertical-align: bottom;

    @media (max-width: 400px) {
      margin-right: 0px;
    }
  }

  div:first-of-type {
    display: flex;
    flex-direction: column;

    div:first-of-type {
      display: flex;
      flex-direction: row;

      @media (max-width: 400px) {
        flex-direction: column;
        padding-bottom: 15px;

        h1 {
          text-align: center;
        }
      }

      h1 {
        font-size: 1.9em;
        margin-right: 10px;
      }
    }
  }
`;

function PilotDisplay({ authContext }) {
  const queryParams = new URLSearchParams(useLocation().search);

  var characterId = queryParams.get("character_id") || authContext.current.id;
  const [filter, setFilter] = React.useState(null);
  const [basicInfo, refreshBasicInfo] = useApi(`/api/pilot/info?character_id=${characterId}`);
  const [fleetHistory] = useApi(`/api/history/fleet?character_id=${characterId}`);
  const [banHistory] = useApi(
    authContext.access["bans-manage"] ? `/api/v2/bans/${characterId}` : null
  );
  const [xupHistory] = useApi(`/api/history/xup?character_id=${characterId}`);
  const [skillHistory] = useApi(`/api/history/skills?character_id=${characterId}`);
  const [notes] = useApi(
    authContext.access["notes-view"] ? `/api/notes?character_id=${characterId}` : null
  );


  usePageTitle("Pilot");
  return (
    <>
      {authContext.access["bans-manage"] && <AccountBannedBanner bans={banHistory} />}

      <PageMast>
        <img
          src={`https://images.evetech.net/characters/${basicInfo?.id ?? 1}/portrait?size=128`}
          alt="Character Portrait"
        />
        <div>
          <div style={{ display: "flex", alignItems: "center" }}>
            <h1>{basicInfo && basicInfo.name}</h1><h3> - {basicInfo && basicInfo.corp_name} {basicInfo && basicInfo.alliance_name && `(${basicInfo.alliance_name})`}</h3>
          </div>
          <PilotTags style={{ flexWrap: "flex" }} tags={basicInfo && basicInfo.tags} />
        </div>
      </PageMast>

      {authContext.current.id !== characterId && (
        <InputGroup style={{ marginBottom: "20px" }}>
          {authContext.access["notes-add"] && (
            <NavButton to={`/fc/notes/add?character_id=${characterId}`}>Write note</NavButton>
          )}
          {authContext.access["access-manage"] && (
            <CommanderModal
              character={basicInfo ?? { id: parseInt(characterId), name: "" }}
              isRevokeable
              handleRefresh={refreshBasicInfo}
            />
          )}
          {authContext.access["badges-manage"] && (
            <CharacterBadgeModal
              character={basicInfo ?? { id: parseInt(characterId), name: "" }}
              refreshData={refreshBasicInfo}
            />
          )}
          {authContext.access["waitlist-tag:TRAINEE"] && (
            <Button
              title="Open Show Info Window"
              onClick={(evt) =>
                errorToaster(ToastContext, OpenWindow(basicInfo.id, authContext.current.id))
              }
            >
              Show Info <FontAwesomeIcon fixedWidth icon={faExternalLinkAlt} />
            </Button>
          )}
        </InputGroup>
      )}
      <Row>
        <Col xs={4} md={6}>
          <Title>
            History
            <FilterButtons>
              <a
                onClick={(evt) => setFilter(null)}
                style={{ marginRight: "0.5em" }}
                title="Clear Filters"
              >
                <FontAwesomeIcon fixedWidth icon={faTimes} />
              </a>
              <a onClick={(evt) => setFilter("skill")} title="Skill History">
                <FontAwesomeIcon fixedWidth icon={faGraduationCap} />
              </a>
              <a onClick={(evt) => setFilter("fit")} title="X-UP History">
                <FontAwesomeIcon fixedWidth icon={faPen} />
              </a>
              <a onClick={(evt) => setFilter("fleet")} title="Fleet History">
                <FontAwesomeIcon fixedWidth icon={faPlane} />
              </a>
              {authContext.access["notes-view"] && (
                <a onClick={(evt) => setFilter("note")} title="Pilot Notes">
                  <FontAwesomeIcon fixedWidth icon={faClipboard} />
                </a>
              )}
              {authContext.access["bans-manage"] && (
                <a onClick={(evt) => setFilter("ban")} title="Character Ban History">
                  <FontAwesomeIcon fixedWidth icon={faBan} />
                </a>
              )}
            </FilterButtons>
          </Title>

          <PilotHistory
            filter={filter ? (type) => type === filter : null}
            banHistory={banHistory}
            fleetHistory={fleetHistory && fleetHistory.activity}
            skillHistory={skillHistory && skillHistory.history}
            xupHistory={xupHistory && xupHistory.xups}
            notes={notes && notes.notes}
          />
        </Col>
        <Col xs={4} md={2}>
          <ControlButtons>
            <div>Account Actions</div>
            <div className={'buttons'}>
              {(authContext.characters.map(c => c.id).includes(characterId) && (
                <UnlinkChar character_id={characterId} />
              ))}
            
              {(authContext?.access['waitlist-tag:TRAINEE'] || authContext?.access['wiki-editor']) && authContext.current.id === characterId && (
                <>
                  {authContext?.access['waitlist-tag:TRAINEE'] && (
                    <NavButton to="/auth/start/fc" style={{ textAlign: 'center' }}>
                      <span style={{ marginRight: '10px' }}>Add ESI Scopes</span>
                      <FontAwesomeIcon fixedWidth icon={faExternalLinkAlt} />
                    </NavButton>
                  )}
                  <WikiPassword />
                </>
              )}
            </div>
          </ControlButtons>


          <Title>Time in fleet</Title>
          <ActivitySummary summary={fleetHistory && fleetHistory.summary} />

          <AltCharacters character={basicInfo?.id} />
        </Col>
      </Row>
    </>
  );
}
