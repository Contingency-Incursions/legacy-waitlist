import styled from "styled-components";
import { Label as BaseLabel,Input as BaseInput, Button, Textarea } from "../../../Components/Form";
import { ImplantDisplay } from "../../../Components/FitDisplay";
import { useContext, useState, useMemo, useEffect } from "react";
import { AuthContext, ToastContext } from "../../../contexts";
import { apiCall, errorToaster, useApi } from "../../../api";
//import A from "../../../Components/A";
import Spinner from "../../../Components/Spinner";

const FormGroup = styled.div`
  flex-grow: 2;
  padding-bottom: 20px;
`;

const H2 = styled.h2`
  padding-bottom: 12px;
  font-size: 1.75em;
  flex: 0 0 100%;
`;

const Label = styled(BaseLabel)`
  &::selection {
    background: none;
  }
`;

const Input = styled(BaseInput)`
  max-width: 75px;
  margin-right: 12px;
  -moz-appearance: textfield;
  &::-webkit-outer-spin-button,
  &::-webkit-inner-spin-button {
      -webkit-appearance: none;
  }
`;


const exampleFit = String.raw`
[Kronos, CI Kronos Elite]
Neutron Blaster Cannon II
Neutron Blaster Cannon II
Neutron Blaster Cannon II
Neutron Blaster Cannon II
'Peace' Large Remote Armor Repairer
Imperial Navy Large Remote Capacitor Transmitter
Bastion Module I

Large Micro Jump Drive
Shadow Serpentis Sensor Booster
Shadow Serpentis Tracking Computer
...
`.trim();

async function validateFit({ character_id, eft }) {
  return await apiCall("/api/fit-check", {
    json: {
      eft,
      character_id,
    },
  });
}

const ValidateFit = ({ alt, fits, max_alts, callback, setAlt, setFits, setMaxAlts }) => {
  const authContext = useContext(AuthContext);
  const toastContext = useContext(ToastContext);

  const [ pending, setPending ] = useState(false);

  const [ implants ] = useApi(`/api/implants?character_id=${authContext.current.id}`);

  const handleFitValidation = (e) => {
    e.preventDefault();

    if (pending) {
      return; // Stop users from clicking the button twice
    }

    setPending(true);

    errorToaster(
      toastContext,
      validateFit({
        character_id: authContext?.current.id,
        eft: fits
      })
      .then((res) => callback(res))
      .finally(() => setPending(false))
    );
  }

  const is_boxer = useMemo(() => {
    const main = authContext.characters.find((e) => e.main);
    return main.badges.includes('BOXER');
  }, [authContext])

  useEffect(() => {
    const main = authContext.characters.find((e) => e.main);
    setMaxAlts(main.boxer_alts);
  }, [setMaxAlts, authContext])

  return (
    <>
      <H2>Submit fit</H2>

      <form onSubmit={handleFitValidation}>
        <FormGroup>
          <Label htmlFor="fit" required>Paste Fit(s):</Label>
          <Textarea id="fit" value={fits} onChange={(e) => setFits(e.target.value)} placeholder={exampleFit} required />
        </FormGroup>

        <FormGroup>
          <Label htmlFor="alt">
            <input id="alt" type="checkbox" checked={alt} onChange={(e) => setAlt(!alt)} />
            This pilot is an alt
          </Label>
        </FormGroup>

        {is_boxer && (
                  <FormGroup>
                  <Label htmlFor="boxer_alts">What is max boxer alts you can bring?</Label>
                    <Input id="boxer_alts"
                      type="number"
                      min="0"
                      max="20"
                     value={max_alts}
                     onChange={(e) => setMaxAlts(e.target.value)}
                     step='1'
                      required
                    /> alts
                </FormGroup>
        )}


        <Button variant="success" disabled={pending}>X UP</Button>
        {/* <A href={`https://wiki.${window.location.host}/guides/waitlist`} target="_blank">
          How do I join the waitlist?
        </A> */}
      </form>

      <div id="implants">
        { implants ?
           <ImplantDisplay implants={implants.implants} name={`${authContext.current.name}'s capsule`} /> :
           <Spinner /> }
      </div>
    </>
  )
}

export default ValidateFit;