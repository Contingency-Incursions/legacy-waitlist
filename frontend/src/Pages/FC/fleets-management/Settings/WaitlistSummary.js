import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Card, Details, Feature } from "./components";
import { faUserClock } from "@fortawesome/free-solid-svg-icons";
import { useMemo } from "react";

const WaitlistSummary = ({ xups }) => {
  let characters = [];
  xups?.forEach((x) => {
    x.fits?.forEach((f) => {
      if (!characters.includes(f.character.id)) {
        characters.push(f.character.id);
      }
    });
  });

  const boxer_alts_count = useMemo(() => {
    let sum = 0;
    if (xups === undefined) {
      return sum;
    }
    xups.forEach((xup) => {
      if (xup.max_alts !== null) {
        sum = sum + xup.max_alts;
      }
    });
    return sum;
  }, [xups]);

  return (
    <Card>
      <div>
        <Feature>
          <FontAwesomeIcon fixedWidth icon={faUserClock} size="2x" />
        </Feature>
        <Details>
          <p>Waitlist</p>
          <div>
            <p>
              <span
                data-tooltip-id="tip"
                data-tooltip-html={`${xups?.length + boxer_alts_count} users on WL`}
              >
                {xups?.length + boxer_alts_count}
              </span>
              &nbsp; // &nbsp;
              <span
                data-tooltip-id="tip"
                data-tooltip-html={`${characters?.length + boxer_alts_count} characters on WL`}
              >
                {characters?.length + boxer_alts_count}
              </span>
            </p>
          </div>
        </Details>
      </div>
    </Card>
  );
};

export default WaitlistSummary;
