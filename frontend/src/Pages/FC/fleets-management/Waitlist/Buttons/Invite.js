import { useContext, useState } from "react"
import { apiCall, errorToaster } from "../../../../../api";
import { ToastContext } from "../../../../../contexts"
import { Button } from "./Button";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faSpinner, faCheck } from "@fortawesome/free-solid-svg-icons"

async function invite(id, review_comment) {
  return await apiCall("/api/waitlist/invite", {
    json: { id, review_comment },
  });
}

const InviteButton = ({ fitId, isRejected }) => {
  const [ pending, isPending ] = useState(false);
  const toastContext = useContext(ToastContext);

  const handleClick = () => {
    isPending(true);
    errorToaster(
      toastContext,
      invite(fitId)
      .finally(_ => isPending(false))
    );
  }


  return (
    <>
      <Button type="button"
        variant="primary"
        data-tooltip-id="tip"
        data-tooltip-html={!isRejected ? "Invite" : "Fit rejected"}
        disabled={isRejected || pending}
        onClick={handleClick}
      >
         <FontAwesomeIcon fixedWidth icon={!pending ? faCheck : faSpinner} spin={pending} />
      </Button>
    </>
  )
}

export default InviteButton;
