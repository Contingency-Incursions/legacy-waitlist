// import { useApi } from "../../api";
// import _ from "lodash";
import { useMemo, useContext, useState } from "react";
import { Content } from "../../Components/Page";
// import { Cell, CellHead, Row, Table, TableBody, TableHead } from "../../Components/Table";
// import { formatDatetime, formatDuration } from "../../Util/time";
// import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
// import { faStar } from "@fortawesome/free-solid-svg-icons";
import { usePageTitle } from "../../Util/title";
import { Switch } from "../../Components/Form";
import { Card, Details } from "./fleets-management/Settings/components";
import { SettingsContext } from "../../Contexts/Settings";
import { apiCall, errorToaster } from "../../api";
import { ToastContext } from "../../contexts";

export function WaitlistSettings() {
  usePageTitle("Waitlist Settings");
  const { settings } = useContext(SettingsContext);
  const toastContext = useContext(ToastContext);

  const [pending, isPending] = useState(false);

  const change_anti_gank = (e) => {
    if (pending) {
      return;
    }
    isPending(true);

    errorToaster(
      toastContext,
      apiCall(`/api/v2/settings/anti_gank`, {
        method: "POST",
        json: {
          setting: e,
        },
      }).finally(() => isPending(false))
    );
  };

  let anti_gank_mode = useMemo(() => {
    return settings.anti_gank === "t" ? true : false;
  }, [settings]);

  return (
    <Content>
      <h2>Waitlist Settings</h2>
      <Card>
        <div>
          <Switch checked={anti_gank_mode} onChange={change_anti_gank} />
          <Details>
            <p>Anti-gank mode</p>
            <div>{anti_gank_mode ? "On" : "Off"}</div>
          </Details>
        </div>
      </Card>
    </Content>
  );
}
