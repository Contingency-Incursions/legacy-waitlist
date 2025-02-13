import styled, { css } from "styled-components";
import { NavLink } from "react-router-dom";

export const inputStyle = css`
  position: relative;
  padding: 0 1em;
  font-size: 1em;
  border: solid ${(props) => (props.variant ? "0px" : "1px")};
  border-color: ${(props) => props.theme.colors.accent2};
  border-radius: 4px;

  background-color: ${(props) => props.theme.colors[props.variant || "input"].color};
  color: ${(props) => props.theme.colors[props.variant || "input"].text} !important;
  display: inline-block;
  font: inherit;

  transition: ease-in-out 0.3s;

  &.active {
    border-color: ${(props) => props.theme.colors.active};
  }
  &:hover:not(:disabled):not(.static) {
    color: ${(props) => props.theme.colors[props.variant || "input"].text};
    border-color: ${(props) => props.theme.colors.accent3};
    background-color: ${(props) => props.theme.colors[props.variant || "input"].accent};

    &.active {
      border-color: ${(props) => props.theme.colors.active};
    }
  }
  &:focus:not(:disabled):not(.static) {
    outline: none;
    box-shadow: 0 0 0 2px ${(props) => props.theme.colors.outline};
  }
  &:disabled {
    cursor: not-allowed;
  }
  &.static {
    cursor: default;
  }
  &:disabled,
  &.static {
    color: ${(props) => props.theme.colors[props.variant || "input"].disabled};
  }
  @media (max-width: 480px) {
    padding: 0 0.8em;
  }
`;

export const Button = styled.button.attrs((props) => ({
  className: `${props.outline ? "btn-outline" : ""} ${props.active ? "active" : ""} ${props.static ? "static" : ""}`.trim(),
}))`
  ${inputStyle}
  height: 2.5em;
  cursor: pointer;
  border-radius: 4px;

  &:disabled {
    opacity: 0.8;
  }

  &.btn-outline {
    background: none;
    border: solid 1.5px ${(props) => props.theme.colors[props.variant || "input"].color};
    transition: ease-in-out 0.3s;
    &:hover, &:active {
      border: solid 1.5px ${(props) => props.theme.colors[props.variant || "input"].accent}!important;
    }
  }
`;

export const MobileButton = styled.button.attrs((props) => ({
  className: `${props.active ? "active" : ""} ${props.static ? "static" : ""}`,
}))`
  ${inputStyle}
  height: 2.5em;
  width: 3.35em;
  background-color: unset;
  align-self: center;
  cursor: pointer;
  @media (min-width: 481px) {
    display: none;
  }
`;

export const AButton = styled.a.attrs((props) => ({
  className: `${props.active ? "active" : ""} ${props.static ? "static" : ""}`,
}))`
  ${inputStyle}
  height: 2.5em;
  text-decoration: none;
  line-height: 2.5em;
`;

export const Label = styled.label`
  display: block;
  margin-bottom: 10px;

  &[required] {
    ::after {
      content: "  *";
      color: red;
      font-size: 15px;
      font-weight: bolder;
    }
  }
`;

export const NavButton = styled(NavLink).attrs((props) => ({
  className: `${props.active ? "active" : ""} ${props.static ? "static" : ""}`,
}))`
  ${inputStyle}
  height: 2.5em;
  text-decoration: none;
  line-height: 2.5em;
`;

export const Input = styled.input`
  ${inputStyle}
  height: 2.5em;
`;

export const Radio = styled.input.attrs({ type: "radio" })`
  ${inputStyle}
`;

export const Select = styled.select`
  ${inputStyle}
  height: 2.5em;
  appearance: auto;

  > option {
    background-color: ${(props) => props.theme.colors.background};
    color: ${(props) => props.theme.colors.text};
  }
`;

export const Textarea = styled.textarea`
  ${inputStyle}
  padding: 1em;

  &:focus::placeholder {
    color: transparent;
  }
`;

export const InputGroup = styled.div`
  display: flex;
  flex-wrap: wrap;
  > * {
    z-index: 1;
    margin: 0;
  }
  > :not(:last-child) {
    border-top-right-radius: 0;
    border-bottom-right-radius: 0;
  }
  > :not(:first-child) {
    border-top-left-radius: 0;
    border-bottom-left-radius: 0;
    margin-left: -1px;
  }
  > .active:hover {
    z-index: 4;
  }
  > .active {
    z-index: 3;
  }
  > :hover {
    z-index: 2;
  }
  @media (max-width: 480px) {
    ${(props) =>
      !props.fixed &&
      `
	  * {
		  padding-right: 0.3em;
		  padding-left: 0.3em;
		  font-size: 0.85em;
		  svg {
			  padding: 0;
			  margin: 0 0.3em 0 0.3em;
		  }
	  }
  `}
  }
`;

export const Buttons = styled.div`
  display: flex;
  flex-wrap: wrap;

  > * {
    margin-bottom: ${(props) => (props.marginb ? props.marginb : "0.5em")};
    margin-right: 0.5em;
  }
  > :not(:last-child) {
    @media (max-width: 480px) {
      margin-bottom: 0.4em;
      margin-right: 0.3em;
    }
  }
`;

export const CenteredButtons = styled.div`
  display: flex;
  justify-content: center;
  > * {
    width: ${(props) => (props.size ? props.size : "inherit")};
    margin: 0.2em;
  }
`;

export const Highlight = styled.b`
  color: ${(props) => props.theme.colors.highlight.text};
  &:hover:not(:disabled):not(.static) {
	cursor: pointer;
	color:  ${(props) => props.theme.colors.highlight.active};
`;


const SwitchDOM = styled.label`
  position: relative;
  display: inline-block;
  width: 54px;
  height: 28px;

  input {
    opacity: 0;
    width: 0;
    height: 0;

    &:checked + .slider {
      background-color: ${(props) => props.theme.colors[props.variant].color};

      &:before {
        transform: translateX(26px);
      }
    }
  }

  span {
    background-color: ${props => props.theme.colors.accent2};
    border-radius: 34px;
    cursor: pointer;
    position: absolute;
    bottom: 0;
    top: 0;
    left: 0;
    right: 0;
    transition: .4s;

    &:before {
      background-color: white;
      border-radius: 50%;
      content: "";
      position: absolute;
      bottom: 4px;
      left: 4px;
      height: 20px;
      width: 20px;
      transition: .4s;
    }
  }
`;

export const Switch = ({ id, checked = false, variant = 'primary', onChange }) => {
  return (
    <SwitchDOM htmlFor={id} variant={variant}>
      <input type="checkbox"
        checked={checked}
        onChange={_ => onChange(!checked)}
      />
      <span className='slider round' />
    </SwitchDOM>
  )
}
