import { useApi } from "../../api";
import { InputGroup, Button, Buttons, AButton } from "../../Components/Form";
import { Fitout, ImplantOut } from "./FittingSortDisplay";
import { PageTitle } from "../../Components/Page";
import { useLocation, useNavigate } from "react-router-dom";
import { usePageTitle } from "../../Util/title";
import { InfoNote } from "../../Components/NoteBox";

export function Fits() {
  const queryParams = new URLSearchParams(useLocation().search);
  const navigate = useNavigate();
  var tier = queryParams.get("Tier") || "Starter";
  const setTier = (newTier) => {
    queryParams.set("Tier", newTier);
    navigate({search: queryParams.toString()})
  };

  return <FitsDisplay tier={tier} setTier={setTier} />;
}

function FitsDisplay({ tier, setTier = null }) {
  usePageTitle(`${tier} Fits`);
  const [fitData] = useApi(`/api/fittings`);
  if (fitData === null) {
    return <em>Loading fits...</em>;
  }

  return (
    <>
      <PageTitle>HQ FITS</PageTitle>
      <AButton href="/skills" style={{ float: "right" }}>
        Skill Plans
      </AButton>
      {setTier != null && (
        <Buttons style={{ marginBottom: "0.5em" }}>
          <InputGroup>
            <Button active={tier === "Starter"} onClick={(evt) => setTier("Starter")}>
              Starter
            </Button>
            <Button active={tier === "Basic"} onClick={(evt) => setTier("Basic")}>
              Basic
            </Button>
            <Button active={tier === "Advanced"} onClick={(evt) => setTier("Advanced")}>
              Advanced
            </Button>
            <Button active={tier === "Elite"} onClick={(evt) => setTier("Elite")}>
              Elite
            </Button>
          </InputGroup>
          <InputGroup>
            <Button active={tier === "Logistics"} onClick={(evt) => setTier("Logistics")}>
            Logistics
            </Button>
          </InputGroup>
          <InputGroup>
            <Button active={tier === "Antigank"} onClick={(evt) => setTier("Antigank")}>
              Antigank
            </Button>
          </InputGroup>
          <InputGroup>
            <AButton
              href={`https://wiki.${window.location.host}/guides/travelling-between-focuses#incursion-ship-travel-fits`}
              target="_blank"
            >
              Travel
            </AButton>
          </InputGroup>
        </Buttons>
      )}
      <ImplantOut />
      {tier === "Starter" ? (
        <Fitout data={fitData} tier="Starter" />
      ) : tier === "Basic" ? (
        <Fitout data={fitData} tier="Basic" />
      ) : tier === "Advanced" ? (
        <Fitout data={fitData} tier="Advanced" />
      ) : tier === "Elite" ? (
        <Fitout data={fitData} tier="Elite" />
      ) : tier === "Logistics" ? (
        <Fitout data={fitData} tier="Logistics" />
      ) : tier === "Antigank" ? (
        <>
          <p style={{ margin: '15px 0px 20px 3px', marginBottom: '20px', fontWeight: 'bold' }}>Our anti-gank doctrine used when gankers are in focus.</p>
          <InfoNote>Cruisers are not used with this doctrine.</InfoNote>
          <Fitout data={fitData} tier="Antigank" />
        </>
      ) : null}
    </>
  );
}
