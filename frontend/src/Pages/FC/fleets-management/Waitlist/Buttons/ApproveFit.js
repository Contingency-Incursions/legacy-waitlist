import { useContext, useState } from "react"
import { apiCall, errorToaster } from "../../../../../api";
import { ToastContext } from "../../../../../contexts"

import { Button } from "./Button";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faSpinner, faCheck } from "@fortawesome/free-solid-svg-icons";


async function approveFit(id, review_comment) {
  return await apiCall("/api/waitlist/approve", {
    json: { id, review_comment },
  });
}

const ApproveFitButton = ({ fitId }) => {
  const toastContext = useContext(ToastContext);

  const [ pending, isPending ] = useState(false);

  const handleClick = () => {
    isPending(true);
    errorToaster(
      toastContext,
      approveFit(fitId)
      .finally(_ => isPending(false))
    );
  }

  return (
    <>
      <Button type="button"
        variant="primary"
        data-tooltip-id="tip"
        data-tooltip-html={"Approve Fit"}
        onClick={handleClick}
      >
         <FontAwesomeIcon fixedWidth icon={!pending ? faCheck : faSpinner} spin={pending} />
      </Button>
    </>
  )
}

export default ApproveFitButton;
