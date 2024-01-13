import { useState } from "react";
import { ErrorBoundary as ErrorCatch } from "react-error-boundary";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCheckCircle, faClone } from "@fortawesome/free-solid-svg-icons";
import { faGithub } from "@fortawesome/free-brands-svg-icons";
import styled from "styled-components";

const StackTraceDOM = styled.div`
  h2 {
    font-family: "Monaco", monospace;
    font-size: 24px;
    margin-bottom: 10px;
  }

  button,
  a {
    background: #0c786f;
    border: none;
    border-radius: 10px;
    color: white;
    cursor: pointer;
    font-size: 15px;
    padding: 10px;
    line-height: 10px;
    position: absolute;
    right: 25px;
    transition: ease-in-out 0.3s;

    &:hover:not(:disabled) {
      background: darken(#0c786f, 5.75%);
    }

    &:disabled {
      cursor: not-allowed !important;
    }

    &:not(button) {
      top: 60px;
    }
  }

  pre {
    background: #1f2937;
    border-radius: 0.375rem;
    color: #e5e7eb;
    font-size: 1.2em;
    font-family: "Monaco", monospace;
    font-weight: 400;
    line-height: 1.9;
    overflow-x: hidden;
    padding: 1em 2em;
    position: relative;
    max-width: 80%;
    word-wrap: break-word;
    word-break: break-word;
  }

  code {
    background-color: transparent;
    font-family: inherit;
    margin-right: 50px;
  }
`;

const StackTrace = ({ error }) => {
  const [copied, isCopied] = useState(false);

  const copyToClipboard = () => {
    navigator.clipboard.writeText(error.stack);
    isCopied(true);

    setTimeout(() => isCopied(false), 5 * 1000);
  };

  return (
    <StackTraceDOM>
      <h2>Whoops! An error has occured:</h2>
      <pre>
        <button
          onClick={copyToClipboard}
          disabled={copied}
          data-tooltip-id="tip"
          data-tooltip-content="Copy Error to Clipboard"
        >
          <FontAwesomeIcon fixedWidth icon={!copied ? faClone : faCheckCircle} />
        </button>

        <a
          href={`https://github.com/Contingency-Incursions/legacy-waitlist/issues/new`}
          target="_blank"
          rel="noreferrer"
          data-tooltip-id="_tip"
          data-tooltip-content="Create Bug Report"
        >
          <FontAwesomeIcon fixedWidth icon={faGithub} />
        </a>
        <code>{error.stack}</code>
      </pre>
    </StackTraceDOM>
  );
};

const ErrorBoundary = ({ children }) => {
  return <ErrorCatch FallbackComponent={StackTrace}>{children}</ErrorCatch>;
};

export default ErrorBoundary;
