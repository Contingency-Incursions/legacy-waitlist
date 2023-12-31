import React from "react";
import { BrowserRouter } from "react-router-dom";
import { processAuth } from "../Pages/Auth";
import { ToastDisplay } from "../Components/Toast";
import { AuthContext, ToastContext, EventContext } from "../contexts";
import { ThemeProvider, createGlobalStyle } from "styled-components";
import { WaitlistRoutes } from "./routes";
import { Container } from "react-awesome-styled-grid";
import { Menu } from "./Menu";
import { Tooltip } from 'react-tooltip'
import { createConsumer } from "@rails/actioncable";
import { SettingsProvider } from "../Contexts/Settings";
import AntiGankBanner from "../Components/AntiGankBanner"

import AnnouncementBanner from "../Components/AnnouncementBanner";
import ErrorBoundary from './ErrorBoundary';
import Footer from "./Footer";
import theme from "./theme.js";

import 'react-tooltip/dist/react-tooltip.css'
import "./reset.css";

const GlobalStyle = createGlobalStyle`
  html {
    // overflow-y: scroll;
    text-rendering: optimizeLegibility;
    font-size: 16px;
    min-width: 300px;
  }
  body {
    min-height: 100vh;
    background-color: ${(props) => props.theme.colors.background};
    color: ${(props) => props.theme.colors.text};
    font-family: ${(props) => props.theme.font.family};
    line-height: 1.5;
    font-weight: 400;
  }
  em, i {
    font-style: italic;
  }
  strong, b {
    font-weight: bold;
  }
`;

export default class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      auth: null,
      toasts: [],
      events: null,
      eventErrors: 0,
      theme:
        (window.localStorage &&
          window.localStorage.getItem("theme") in theme &&
          window.localStorage.getItem("theme")) ||
        "Dark",
    };
  }

  componentDidUpdate() {
    if (this.state.auth && !this.state.events) {

      const consumer = createConsumer('/api/cable');
      this.setState({ events: consumer });
    }
  }

  componentDidMount() {
    processAuth((whoami) => this.setState({ auth: whoami }));
  }

  addToast = (toast) => {
    this.setState({ toasts: [...this.state.toasts, toast] });
  };

  changeCharacter = (newChar) => {
    var newState = { ...this.state.auth };
    var theChar = this.state.auth.characters.filter((char) => char.id === newChar)[0];
    newState.current = theChar;
    this.setState({ auth: newState });
  };


  


  render() {
    return (
      <React.StrictMode>
        <ThemeProvider theme={theme[this.state.theme]}>
          <GlobalStyle sticker={this.state.sticker} />
          <ToastContext.Provider value={this.addToast}>
            <EventContext.Provider value={this.state.events}>
              <AuthContext.Provider value={this.state.auth}>
              <SettingsProvider>
                  <BrowserRouter>
                  <Container style={{ height: "auto", minHeight: `calc(100vh - 70px)` }}>
                    <Menu
                      onChangeCharacter={(char) => this.changeCharacter(char)}
                      theme={this.state.theme}
                      setTheme={(newTheme) => {
                        this.setState({ theme: newTheme });
                        if (window.localStorage) {
                          window.localStorage.setItem("theme", newTheme);
                        }
                      }}
                      sticker={this.state.sticker}
                      setSticker={(newSticker) => {
                        this.setState({ sticker: newSticker });
                        if (window.localStorage) {
                          window.localStorage.setItem("Sticker", newSticker);
                        }
                      }}
                    />
                    <AntiGankBanner />
                    <AnnouncementBanner />
                    <ErrorBoundary>
                    <WaitlistRoutes />
                      <ToastDisplay
                        toasts={this.state.toasts}
                        setToasts={(toasts) => this.setState({ toasts })}
                      />
                    </ErrorBoundary>
                  </Container>
                </BrowserRouter>
                <Tooltip id="tip" style={{ zIndex: 150 }} />
                <Footer />
                  </SettingsProvider>

              </AuthContext.Provider>
            </EventContext.Provider>
          </ToastContext.Provider>
        </ThemeProvider>
      </React.StrictMode>
    );
  }
}
