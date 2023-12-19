import { useContext, useState, useMemo } from "react";
import { AuthContext, ToastContext } from "../../../contexts";
import { useApi } from "../../../api";
import { Box } from "../../../Components/Box";
import { Button, Buttons, Label } from "../../../Components/Form";
import ConfigureSquadsForm from "./ConfigureSquadsForm";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faTasks } from "@fortawesome/free-solid-svg-icons";
import { Modal } from "../../../Components/Modal";
import styled from "styled-components";
import { apiCall, errorToaster } from "../../../api";

const Form = styled.form`
  display: flex;
  flex-wrap: wrap;

  div {
    padding: 10px;
  }
`;

const FormGroup = styled.div`
  flex-grow: 2;
  padding-bottom: 20px;
`;

const H2 = styled.h2`
  font-size: 1.5em;
  margin-bottom: 25px;

  svg {
    margin-right: 15px;
    font-size: 35px;
  }
`;

const RegisterFleetBtn = ({ refreshFunction }) => {
  const authContext = useContext(AuthContext);
  const toastContext = useContext(ToastContext);

  const [ open, setOpen ] = useState(false);
  const [ pending, isPending ] = useState(false);
  const [ defaultSquads, isDefaultSquads ] = useState(true);
  const [ defaultMotd, isDefaultMotd ] = useState(true);
  const [ squadMappings, setSquadMappings ] = useState({});
  const [ fleet ] = useApi(`/api/fleet/info?character_id=${authContext?.current?.id}`, true);
  const [ data ] = useApi('/api/categories');

  // Flatten fleet squads into single array
  let squads = useMemo(() => {
    let squads = [];
    fleet?.wings.forEach(wing => {
      wing?.squads.map(squad => {
        squads.push({ 
          label: `${wing.name} > ${squad.name}`,
          id: squad.id,
          wing_id: wing.id
        })
      });
    });

    return squads;
  }, [fleet]);

  let categories = useMemo(() => {
    return data?.categories;
  })

  // Only fleet admins: Instructor/Leadership should see this
  if (!authContext?.access['fleet-invite']) {
    return null;
  }

  const handleSubmit = (e) => {
    e.preventDefault();

    if (pending) {
      return; // stop users from clicking this twice
    }
    isPending(true);

    let json = {
      default_motd: defaultMotd,
      default_squads: defaultSquads,
      boss_id: authContext.current.id,
      squads: null
    };

    if (!defaultSquads) {
      // todo: this needs to load in data from the wizard
      json.squads = Object.keys(squadMappings).map(category => {
        return {
          category: category,
          ...squadMappings[category]
        }
      })
    }

    errorToaster(
      toastContext,
      apiCall(`/api/v2/fleets`, {
        method: 'POST',
        json
      })
      .then((e) => {
        window.location.assign(e);
      })
      .finally(() => isPending(false))
    );
  }

  if(fleet === null){
    return null;
  }

  return (
    <>
      <Button variant="primary" onClick={_ => setOpen(true)}>
        Register Fleet
      </Button>

      <Modal open={open} setOpen={setOpen}>
        <Box style={{ minWidth: "600px" }}>
          <H2>
            <FontAwesomeIcon fixedWidth icon={faTasks} />
            Register Fleet
          </H2>

          <Form onSubmit={handleSubmit}>
            <FormGroup>
              <Label htmlFor="motd">
                <input id="motd" type="checkbox" checked={defaultMotd} onChange={e => isDefaultMotd(!defaultMotd)} />
                Use Default MOTD?
              </Label>
            </FormGroup>

            <FormGroup style={{ }}>
              <Label htmlFor="squad">
                <input id="squad" type="checkbox" checked={defaultSquads} onChange={e => isDefaultSquads(!defaultSquads)} />
                Use Default Squads?
              </Label>
            </FormGroup>

            { 
            !defaultSquads && <ConfigureSquadsForm 
            squads={squads} 
            categories={categories} 
            squadMappings={squadMappings} 
            setSquadMappings={setSquadMappings} 
            /> 
            }

            <Buttons style={{ width: '100%' }}>
              <Button variant='primary'>
                Submit
              </Button>

              <Button type="button" onClick={_ => setOpen(false)}>
                Cancel
              </Button>
            </Buttons>
          </Form>
        </Box>
      </Modal>
    </>
  )
}

export default RegisterFleetBtn;
