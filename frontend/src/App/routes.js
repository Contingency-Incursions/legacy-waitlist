import { useContext } from "react";

import { Route, Routes } from "react-router-dom";
import { AuthContext } from "../contexts";

import { AuthStart, AuthCallback, AuthLogout } from "../Pages/Auth";
import AnnouncementsPage from "../Pages/FC/Announcements";
import BadgesPage from "../Pages/FC/Badges";
import BansPage from "../Pages/FC/Bans";
import CommandersPage from "../Pages/FC/Commanders";
import { FCMenu } from "../Pages/FC/Index";
import { Fits } from "../Pages/Fits";
import { Fleet, FleetRegister } from "../Pages/FC/Fleet";
import { FleetCompHistory } from "../Pages/FC/FleetCompHistory";
import { ISKh, ISKhCalc } from "../Pages/ISKh";
import { NoteAdd } from "../Pages/FC/NoteAdd";
import { Pilot } from "../Pages/Pilot";
import Plans from "../Pages/SkillPlans/Plans";
import ReportsPage from "../Pages/FC/Reports";
import { Search } from "../Pages/FC/Search";
import Skills from "../Pages/Skills";
import { Statistics } from "../Pages/FC/Statistics";
import { Waitlist } from "../Pages/Waitlist";
import { WaitlistSettings } from "../Pages/FC/WaitlistSettings";

import { E401, E403, E404 } from "../Pages/Errors";
import FleetsIndexPage from "../Pages/FC/fleets";
import FleetsManagementPage from "../Pages/FC/fleets-management";
import { FcStats } from "../Pages/FC/FCStats";

function AuthenticatedRoute(props) {
  const authContext = useContext(AuthContext);
  let { component, loginRequired = false, access = null } = props;

  if (!loginRequired && !access) {
    return component; // Page doesn't require authentication
  }

  if (!authContext) {
    return <E401 />; // User isn't authenticated
  }

  if (access && !authContext.access[access]) {
    return <E403 />; // User lacks the required permission
  }

  // All auth checks OK
  return component;
}

export function WaitlistRoutes() {
  const authContext = useContext(AuthContext);

  return (
    <Routes>
      <Route
        path="/"
        element={
          <AuthenticatedRoute component={<Waitlist />} loginRequired authContext={authContext} />
        }
      />

      <Route path="/fits" element={<Fits />} />
      <Route path="/isk-h" element={<ISKh />} />
      <Route path="/isk-h/calc" element={<ISKhCalc />} />
      <Route path="/pilot" element={<Pilot />} />
      <Route path="/skills" element={<AuthenticatedRoute component={<Skills />} />} />
      <Route path="/skills/plans" element={<Plans />} />

      <Route
        path="/fc"
        element={<AuthenticatedRoute component={<FCMenu />} access="waitlist-tag:HQ-FC" />}
      />
      <Route
        path="/fc/announcements"
        element={
          <AuthenticatedRoute component={<AnnouncementsPage />} access="waitlist-tag:HQ-FC" />
        }
      />
      <Route
        path="/fc/badges"
        element={<AuthenticatedRoute component={<BadgesPage />} access="badges-manage" />}
      />
      <Route
        path="/fc/bans"
        element={<AuthenticatedRoute component={<BansPage />} access="bans-manage" />}
      />
      <Route
        path="/fc/commanders"
        element={<AuthenticatedRoute component={<CommandersPage />} access="commanders-view" />}
      />
      <Route
        path="/fc/fleet"
        element={<AuthenticatedRoute component={<Fleet />} access="fleet-view" />}
      />
      <Route
        path="/fc/fleet/register"
        element={<AuthenticatedRoute component={<FleetRegister />} access="fleet-view" />}
      />
      <Route
        path="/fc/fleet/fc_stats"
        element={<AuthenticatedRoute component={<FcStats />} access="fleet-history-view" />}
      />
      <Route
        path="/fc/fleet/history"
        element={
          <AuthenticatedRoute component={<FleetCompHistory />} access="fleet-history-view" />
        }
      />
      <Route
        path="/fc/notes/add"
        element={<AuthenticatedRoute component={<NoteAdd />} access="notes-add" />}
      />
      <Route
        path="/fc/search"
        element={<AuthenticatedRoute component={<Search />} access="waitlist-tag:HQ-FC" />}
      />
      <Route
        path="/fc/stats"
        element={<AuthenticatedRoute component={<Statistics />} access="stats-view" />}
      />
      <Route
        path="/fc/reports"
        element={<AuthenticatedRoute component={<ReportsPage />} access="reports-view" />}
      />
      <Route
        path="/fc/settings"
        element={<AuthenticatedRoute component={<WaitlistSettings />} access="settings-view" />}
      />

      <Route
        path="/fc/fleets"
        element={<AuthenticatedRoute component={<FleetsIndexPage />} access="fleet-view" />}
      />

      <Route
        path="/fc/fleets/:fleetId"
        element={<AuthenticatedRoute component={<FleetsManagementPage />} access="fleet-view" />}
      />

      <Route path="/auth/start" element={<AuthStart />} />
      <Route path="/auth/start/fc" element={<AuthStart fc={true} alt={true} />} />
      <Route path="/auth/start/alt" element={<AuthStart alt={true} />} />
      <Route path="/auth/cb" element={<AuthCallback />} />
      <Route path="/auth/logout" element={<AuthLogout />} />

      <Route path="*" element={<E404 />} />
    </Routes>
  );
}
