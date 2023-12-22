import { useContext, useState } from "react";
import { ToastContext } from "../../../../contexts";
import { apiCall, errorToaster } from "../../../../api";

import { Box } from "../../../../Components/Box";
import { Button as EditButton, Card, Details } from "./components";
import { Button, Buttons, Select } from "../../../../Components/Form";
import { Modal } from '../../../../Components/Modal';

import styled from "styled-components";

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

const SiteType = ({ fleetId, type }) => {
  const toastContext = useContext(ToastContext);

  const [ open, setOpen ] = useState(false);
  const [ selectedValue, setSelectedValue ] = useState(type);
  const [ pending, isPending ] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();

    if (pending) {
      return; // stop users from clicking this twice
    }
    isPending(true);

    errorToaster(
      toastContext,
      apiCall(`/api/v2/fleets/${fleetId}/type`, {
        method: 'POST',
        json: {
          site_type: selectedValue
        }
      })
      .then(() => setOpen(false))
      .finally(() => isPending(false))
    );
  }

  return (
    <>
      <Card>
        <div>
          <Details>
            <p>Site Type</p>
            <div>
              {type ?? '-'}
              <EditButton onClick={_ => setOpen(true)} />
            </div>
          </Details>
        </div>
      </Card>

      <Modal open={open} setOpen={setOpen}>
        <Box>
          <H2>Set Site Type</H2>
          <form onSubmit={handleSubmit}>
            <FormGroup>
              <Select value={selectedValue}  onChange={e => setSelectedValue(e.target.value)}>
               <option value={'hq'}>Headquarters</option>
               <option value={'kundi'}>Kundi Pop</option>
               <option value={'assault'}>Assaults</option>
               <option value={'vg'}>Vanguards</option>
              </Select>
            </FormGroup>
            <Buttons>
              <Button type="submit" variant="primary">Submit</Button>
              <Button type="button" onClick={_ => setOpen(false)}>Cancel</Button>
            </Buttons>
          </form>
        </Box>
      </Modal>
    </>
  )
}

export default SiteType;
