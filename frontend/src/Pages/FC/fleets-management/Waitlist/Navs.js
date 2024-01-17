import styled from "styled-components";
import { Badge as BaseBadge } from "../../../../Components/Badge";
import { useMemo } from "react";

const Badge = styled(BaseBadge)`
  border-radius: 12px;
  margin-left: 5px;
  font-size: 13px;
  font-family: ${(props) => props.theme.font.family};
  font-weight: 400;
`;

const Tabs = styled.div`
  display: flex;
  justify-content: space-evenly;
  margin-bottom: 20px;
  overflow: hidden;

  button {
    background-color: inherit;
    border: none;
    color: ${(props) => props.theme.colors.text};
    cursor: pointer;
    flex-grow: 1;
    font-size: 17px;
    outline: none;
    padding: 6px 5px;
    transition: 0.3s;

    &:hover:not(:disabled) {
      background: ${(props) => props.theme.colors.accent1};
    }

    &.active {
      border-bottom: 3px solid ${(props) => props.theme.colors[props.variant].color};
    }

    &:disabled {
      cursor: not-allowed;
    }
  }
`;

const Navs = ({ categories = [], tab, variant = "success", onClick, fits = [] }) => {
  const Button = ({ name, count }) => {
    return (
      <button className={name === tab ? "active" : null} onClick={(_) => onClick(name)}>
        {name}
        <Badge variant="primary">{count ?? "-"}</Badge>
      </button>
    );
  };

  let nav_categories = useMemo(() => {
    return ["All"].concat(...categories);
  }, [categories]);

  let counts = useMemo(() => {
    let counts = {};
    nav_categories.forEach((category) => {
      let count = 0;
      if (category === "All") {
        count = fits.length;
      } else if (category === "Alts") {
        count = fits.filter((fit) => fit.is_alt === true).length;
      } else {
        count = fits.filter((fit) => fit.category === category).length;
      }
      counts[category] = count;
    });
    return counts;
  }, [nav_categories, fits]);

  return (
    <Tabs variant={variant}>
      {nav_categories?.map((category) => {
        return <Button name={category} count={counts[category]} key={category} />;
      })}
    </Tabs>
  );
};

export default Navs;
