import { useContext } from "react";
import styled from "styled-components";
import { SettingsContext } from "../Contexts/Settings";


const AnnouncementBar = styled.div`
  background: ${(props) => props.theme.colors.secondary.color};
  box-shadow: 0px 3px ${(props) => props.theme.colors.shadow};
  color: ${(props) => props.theme.colors.text};
  margin-bottom: 3.5px;
  padding: 12px;
  position: relative;

  &[data-alert="true"] {
    background: ${(props) => props.theme.colors.danger.color};
    color: ${(props) => props.theme.colors.danger.text};
  }

  small {
    font-style: italic;
    font-size: small;
  }

  .close {
    position: absolute;
    right: 15px;
    top: 15px;
    width: 32px;
    height: 32px;
    opacity: 0.6;
  }
  .close:hover {
    opacity: 1;
    transition: ease-in-out 0.2s;
    cursor: pointer;
  }
  .close:before,
  .close:after {
    position: absolute;
    left: 15px;
    content: " ";
    height: 15px;
    width: 2px;
    background-color: ${(props) => props.theme.colors.secondary.text};
  }
  .close:before {
    transform: rotate(45deg);
  }
  .close:after {
    transform: rotate(-45deg);
  }
`;

const AntiGankBanner = () => {
  const {settings} = useContext(SettingsContext)
  return (
    <>
        {settings.anti_gank == 't' && (
      <div style={{ marginBottom: "10px" }}>
      <AnnouncementBar data-alert={true}>
          <p style={{ paddingLeft: "42px" }}>{"GANKERS THREAT: Keep anti gank fit in dockup, we may need to switch on a moments notice. Waitlist Anti-gank mode is currently active"}</p>
        </AnnouncementBar>
  </div>
    )}
    </>
  );
};

export default AntiGankBanner;
