import { useContext, useState } from "react";
import { ToastContext } from "../../../../contexts";
import { apiCall, errorToaster } from "../../../../api";

import { Box } from "../../../../Components/Box";
import { Button as EditButton, Card, Details, Feature as BaseFeature } from "./components";
import { Button, Buttons, Input as BaseInput } from "../../../../Components/Form";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faExclamationTriangle, faUsers } from "@fortawesome/free-solid-svg-icons";
import { Modal } from "../../../../Components/Modal";

import styled from "styled-components";

const Feature = styled(BaseFeature)`
  border-radius: unset;

  &.overgird {
    color: ${(props) => props.theme.colors.warning.color};
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

const Input = styled(BaseInput)`
  max-width: 75px;
  margin-right: 12px;
  -moz-appearance: textfield;
  &::-webkit-outer-spin-button,
  &::-webkit-inner-spin-button {
    -webkit-appearance: none;
  }
`;

const FleetSize = ({ fleetId, size, max_size }) => {
  const toastContext = useContext(ToastContext);

  const [open, setOpen] = useState(false);
  const [selectedValue, setSelectedValue] = useState(max_size);
  const [pending, isPending] = useState(false);

  const overgrid = size > max_size;

  const handleSubmit = (e) => {
    e.preventDefault();

    if (pending) {
      return; // stop users from clicking this twice
    }
    isPending(true);

    errorToaster(
      toastContext,
      apiCall(`/api/v2/fleets/${fleetId}/size`, {
        method: "POST",
        json: {
          max_size: Number(selectedValue),
        },
      })
        .then(() => setOpen(false))
        .finally(() => isPending(false))
    );
  };

  return (
    <>
      <Card>
        <div>
          <Feature>
            <FontAwesomeIcon
              className={overgrid ? "overgird" : ""}
              fixedWidth
              icon={overgrid ? faExclamationTriangle : faUsers}
              size="2x"
            />
          </Feature>
          <Details>
            <p>On Grid Number</p>
            <div>
              {size ?? "-"} / {max_size ?? "-"}
              <EditButton onClick={(_) => setOpen(true)} />
            </div>
          </Details>
        </div>
      </Card>

      <Modal open={open} setOpen={setOpen}>
        <Box>
          <H2>Set Magic Number</H2>
          <form onSubmit={handleSubmit}>
            <FormGroup>
              <Input
                type="number"
                min="0"
                max="100"
                value={selectedValue}
                onChange={(e) => setSelectedValue(e.target.value)}
                required
              />
            </FormGroup>

            <Buttons>
              <Button type="submit" variant="primary">
                Submit
              </Button>
              <Button type="button" onClick={(_) => setOpen(false)}>
                Cancel
              </Button>
            </Buttons>
          </form>
        </Box>
      </Modal>
    </>
  );
};

export default FleetSize;
