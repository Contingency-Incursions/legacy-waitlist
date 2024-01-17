import React from "react";
import { AuthContext } from "../contexts";
import { EventContext } from "../contexts";
export const SettingsContext = React.createContext();

export function SettingsProvider({ children }) {
  const authContext = React.useContext(AuthContext);
  const events = React.useContext(EventContext);
  const [settings, setSettings] = React.useState({});

  React.useEffect(() => {
    if (authContext && events) {
      events.subscriptions.create(
        { channel: "SettingsChannel" },
        {
          received(data) {
            setSettings(data.data);
          },
        }
      );
    }
  }, [authContext, events, setSettings]);

  React.useEffect(() => {
    fetch("/api/v2/settings").then((response) => {
      if (response.ok) {
        response.json().then((data) => {
          setSettings(data);
        });
      }
    });
  }, [setSettings]);

  return (
    <SettingsContext.Provider value={{ settings, setSettings }}>
      {children}
    </SettingsContext.Provider>
  );
}
