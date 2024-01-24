import { useContext } from "react";
import { ToastContext } from "../../contexts";
import { apiCall, errorToaster } from "../../api";
import { Button } from "../../Components/Form";

async function unlinkChar(id) {
  return await apiCall("/api/account/unlink", {
    method: "POST",
    json: {
      character_id: id,
    },
  });
}

const UnlinkChar = ({character_id}) => {
  const toastContext = useContext(ToastContext);

  const onClick = () => {
    errorToaster(
      toastContext,
      unlinkChar(character_id).then(() => {
        window.location.href = '/'
      })
    );
  };

  return (
    <>
      <Button onClick={() => onClick()}>Unlink Character from account</Button>
    </>
  );
};

export default UnlinkChar;
