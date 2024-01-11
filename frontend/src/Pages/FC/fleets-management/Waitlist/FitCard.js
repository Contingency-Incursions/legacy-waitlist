import { useState, useMemo } from "react";
import BadgeIcon from "../../../../Components/Badge";
import RemoveFit from "./Buttons/RemoveFit";
import ShowInfo from "./Buttons/ShowInfo";
import styled from "styled-components";
import ViewProfile from "./Buttons/ViewProfile";
import ViewSkills from "./Buttons/ViewSkills";
import ApproveFit from "./Buttons/ApproveFit";
import Invite from "./Buttons/Invite";
import FitModal from "./FitModal";
import RejectFit from "./Buttons/RejectFit";
import MessagePilot from "./Buttons/MessagePilot";
import { useApi } from "../../../../api";

const FitCardDOM = styled.div`
  display: flex;
  border-radius: 10px;
  background: ${(props) => props.theme.colors[props.variant]?.accent};
  position: relative;
  width: 370px;
  height: 110px;
  margin-bottom: 5px;
  margin-right: 5px;



  div.grey {
    background: ${(props) => props.theme.colors.accent1};
    border-radius: 0px 0px 10px 10px;
    position: absolute;
    bottom: 0;
    height: 50%;
    width: 100%;
  }
`;

const ImageContainerDOM = styled.div`
  position: relative;
  height: 90px;
  width: 90px;
  user-select: none;
  display: inline-block;

  img.hull {
    border-radius: 50%;
    height: 80px;
    position: absolute;
    top: 15px;
    left: 5px;
    bottom: 15px;
    z-index: 3;

    &:hover {
      cursor: pointer;
    }
  }

  img.character {
    border-radius: 50%;
    height: 40px;
    bottom: -10px;
    right: 0px;
    position: absolute;
    z-index: 4;

    &:hover {
      cursor: pointer;
    }
  }
`;

const ContentContainerDOM = styled.div`
  display: flex;
  flex-direction: column;
  div.names {
    display: flex;
    flex-direction: row;
    div:first-of-type {
      flex-grow: 1;
    }
  }
  div.buttons {
    z-index: 103;
    padding-left: 10px;

    button {
      margin-right: 5px;
      margin-bottom: 7px;
    }

    p {
      font-size: 12px;
      margin-right: 30px;
    }
  }
  flex-grow: 1;
  justify-content: space-between;

  p {
    &:first-of-type {
      border-bottom: 2px solid ${(props) => props.theme.colors.text};
    }
    &:last-of-type {
      font-size: smaller;
      font-style: italic;
    }
  }
`;

const BadgeContainerDOM = styled.div`
  margin-top: 10px;
  margin-left: 10px;
  margin-right: 5px;
  min-width: 25px;
  user-select: none;
`;

const FitState = ({ state, review_comment }) => {
  switch (state) {
    case 'approved':
      return 'success';

    case 'rejected':
      return 'danger';

    default:
      return 'warning';
  }
}

const IMAGE_SERVER_URL = 'https://images.evetech.net/';

const FitCard = ({ fit, bossId, tab, inviteCounts, onInvite, max_alts }) => {
  const [skills] = useApi(`/api/skills?character_id=${fit.character.id}`);
  const BadgeContainer = ({ tags }) => {
    const badges = [
      'BASTION',
      'WEB',
      'WEB-ASPERIANT',
      'ELITE',
      'ELITE-GOLD'
    ];

    const tag = tags?.find(t => badges.includes(t));

    return (
      <BadgeContainerDOM>
        {tag ? <BadgeIcon type={tag} /> : null}
      </BadgeContainerDOM>
    )
  }
  const ImageContainer = ({ character, hull, skills }) => {
    const [ open, setOpen ] = useState(false);
    return (
      <ImageContainerDOM>
        <img
          className='hull'
          src={ IMAGE_SERVER_URL + `types/${hull?.id ?? 1}/icon?size=128` }
          alt={character?.name ?? 'Unknown Pilot'}
          onClick={_ => setOpen(true)}
        />
        <img
          className='character'
          src={ IMAGE_SERVER_URL + `characters/${character?.id ?? 1}/portrait?size=64`}
          alt={character?.name ?? 'Unknown Pilot'}
          onClick={_ => setOpen(true)}
        />
        <FitModal fit={fit} open={open} setOpen={setOpen} skills={skills} />
      </ImageContainerDOM>
    )
  }

  const ContentContainer = ({ character, fit_analysis, id, tags, bossId, inviteCounts, onInvite, skills, max_alts }) => {
    const ALLOWED_TAGS = [
      'NO-EM-806',
      'SLOW',
      'STARTER',
      'UPGRADE-HOURS-REACHED',
      'ELITE-HOURS-REACHED',
      "AT-WAR",
      "FACTION-WAR",
      'NON-DOCTRINE',
      'BOXER'
    ];

    tags = tags.filter(tag => ALLOWED_TAGS.includes(tag));
    if(fit?.is_alt){
      tags.push('ALT');
    }

    return (
      <ContentContainerDOM>
        <div className="names">
          <div>
            <p>{character?.name ?? 'Unknown'} {tags.includes('BOXER') && max_alts && `+ ${max_alts}`}</p>
            <p>{fit_analysis?.name}</p>
          </div>
          <BadgeContainer tags={fit?.tags} />
        </div>
        <div className="buttons">
          <p>
            { tags?.join(', ')}
          </p>

          <RemoveFit fitId={id} />
          <ShowInfo {...character} />
          <ViewSkills character={character} hull={fit?.hull.name} skills={skills} />
          <ViewProfile {...character} />
          <MessagePilot fitId={id} />
          <RejectFit fitId={id} isRejected={fit.state === 'rejected'} />
          {fit.state !== 'approved' && (
            <ApproveFit fitId={id} />
          )}
          {fit.state === 'approved' && (
            <Invite fitId={id} bossId={bossId} isRejected={fit.state === 'rejected'} inviteCounts={inviteCounts} onInvite={onInvite} />
          )}

        </div>
      </ContentContainerDOM>
    )
  }

  let show = useMemo(() => {
    if(!fit) return false;
    if(tab == 'All'){
      return true;
    }
    if(tab == 'Alts') {
      return fit.is_alt === true;
    } else {
      return fit.category === tab;
    }
  },
  [fit, tab])

  return (
    <FitCardDOM variant={FitState(fit)} style={{ display: show ? 'flex' : 'none'}}>
      <ImageContainer character={fit?.character} hull={fit.hull} skills={skills} />
      <ContentContainer {...fit} bossId={bossId} inviteCounts={inviteCounts} onInvite={onInvite} skills={skills} max_alts={max_alts} />
      <div className='grey' />
    </FitCardDOM>
  )
}

export default FitCard;
