/* eslint-disable no-unused-vars */
import { useContext, useState } from "react";
import { useLocation } from "react-router-dom";
import styled from "styled-components";
import { apiCall, errorToaster } from "../../api";
import { Box as BaseBox } from "../../Components/Box";
import { Button } from "../../Components/Form";
import { Modal } from "../../Components/Modal";
import { addToast } from "../../Components/Toast";
import { AuthContext, ToastContext } from "../../contexts";
import VirdianMarauderCheck from "./XupModals/ViridianMarauderCheck";
import WrongFit from "./XupModals/WrongFit";
import ValidateFit from "./XupModals/ValidateFit";
import { IsEmptyObject } from "../../Util/objects";
import { PreloadNotification } from "../../Components/Event";
import { useEffect } from "react";

const Box = styled(BaseBox)`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  overflow-x: hidden;
  max-width: 1000px !important;

  h2 {
    padding-bottom: 12px;
    font-size: 1.75em;
    flex: 0 0 100%;
  }

  a:first-of-type {
    margin-left: 10px;
  }

  #implants {
    margin-top: 33px;
  }

  form {
    padding-right: 20px;
    flex-grow: 1;
  }

  textarea {
    width: 100%;
    min-height: 350px;
    max-height: 800px;
    margin-right: 20px;
    resize: none;
    // overflow-y: hidden;
  }

  @media (max-width: 900px) {
    form {
      flex: 0 0 100%;
      padding-right: 10px !important;

      textarea {
        width: 100%;
        min-height: 30vh;
        max-height: 500px;
      }
    }
  }

  @media (max-width: 1000px) {
    max-width: 1000px;
    form {
      padding-right: 10px !important;
    }
  }
`;

async function submitFit({ character_id, fits, is_alt, max_alts }) {
  await apiCall("/api/waitlist/xup", {
    json: {
      eft: fits,
      character_id,
      is_alt,
      max_alts,
    },
  });
}

const JoinWaitlist = ({ hasFits }) => {
  const authContext = useContext(AuthContext);
  const toastContext = useContext(ToastContext);
  const queryParams = new URLSearchParams(useLocation().search);

  const [open, setOpen] = useState(false);

  const [alt, setAlt] = useState(false);
  const [badFits, setBadFits] = useState(undefined);
  const [fits, setFits] = useState(undefined);
  const [validatedFits, setValidatedFits] = useState(undefined);
  const [max_alts, setMaxAlts] = useState(0);
  const [isMarauder, setMarauder] = useState(false);

  const reset = () => {
    setAlt(false);
    setBadFits(null);
    setFits("");
    setMarauder(false);
  };

  const submit = () => {
    errorToaster(
      toastContext,
      submitFit({
        character_id: authContext.current.id,
        fits,
        is_alt: alt,
        max_alts,
      })
        .then(() => {
          addToast(toastContext, {
            variant: "success",
            message: "Your fits are updated on the waitlist!",
          });
          reset();
          setOpen(false);
          PreloadNotification();
        })
        .finally(() => setMarauder(false))
    );
  };

  return (
    <>
      <Button variant={!hasFits ? "success" : null} onClick={setOpen}>
        {!hasFits ? "Join Waitlist" : "Update Fits"}
      </Button>

      <Modal open={open} setOpen={setOpen}>
        <Box>
          {badFits ? (
            <WrongFit
              fits={badFits}
              goBack={() => reset()}
              xupAnyway={() => {
                setBadFits(null);
                // Check if the ship has a 'Bastion Module I' fitted
                if (validatedFits.some((fit) => fit?.dna.includes(":33400"))) {
                  setMarauder(true);
                  return;
                }
                submit();
              }}
            />
          ) : isMarauder ? (
            <VirdianMarauderCheck onPass={() => submit()} />
          ) : (
            <ValidateFit
              alt={alt}
              setAlt={(a) => setAlt(a)}
              fits={fits}
              setFits={(f) => setFits(f)}
              max_alts={max_alts}
              setMaxAlts={setMaxAlts}
              callback={(fits) => {
                setValidatedFits(fits);

                // A bad fit is one that is not approved and either has
                // not been approved, OR has missing or downgraded items
                let _badFits = fits.filter((fit) => {
                  // If the fit has been approved, then return false
                  if (fit.approved || !fit.fit_analysis) {
                    return false;
                  }

                  return (
                    !IsEmptyObject(fit.fit_analysis.missing) ||
                    !IsEmptyObject(fit.fit_analysis.downgraded) ||
                    !IsEmptyObject(fit.fit_analysis.cargo_missing)
                  );
                });
                if (_badFits.length > 0) {
                  setBadFits(_badFits);
                  return;
                }
                // Check if the ship has a 'Bastion Module I' fitted
                if (fits.some((fit) => fit?.dna.includes(":33400"))) {
                  setMarauder(true);
                  return;
                }
                submit();
              }}
            />
          )}
        </Box>
      </Modal>
    </>
  );
};

export default JoinWaitlist;
