import { useEffect, useState, useMemo } from 'react';
import { useApi } from "../../../api";
import { Label, Select } from "../../../Components/Form";
import styled from "styled-components";

const FormGroup = styled.div`
  flex-grow: 2;
  padding-bottom: 20px;
`;

const DOM = styled.div`
  width: 100%;
  flex-shrink: 10;
`;

const SquadSelect = ({ options, name }) => {
  const [ selected, SetSelected ] = useState();
  
  useEffect(() => {
    SetSelected(options.find(option => option?.label.toLowerCase().includes(name.toLowerCase())));
  }, [options]);

  return (
    <FormGroup>
      <Label htmlFor={name}>
        {name}
      </Label>
      <Select>
        {options?.map((squad, key) => {
          return <option value={undefined} key={key}>{squad.label}</option>
        })}
      </Select>
    </FormGroup>
  )
}

const ConfigureSquadsForm = ({ characterId }) => {
  const [ data ] = useApi('/api/categories');
  const [ fleet ] = useApi(`/api/fleet/info?character_id=${characterId}`);

  // Flatten fleet squads into single array
  let squads = useMemo(() => {
    let squads = [];
    fleet?.wings.forEach(wing => {
      wing?.squads.map(squad => {
        squads.push({ 
          label: `${wing.name} > ${squad.name}`,
          id: squad.id,
          wing_id: wing.id
        })
      });
    });

    return squads;
  }, [fleet]);

  // console.log(data, squads)


  return (
    <DOM>
      {data?.categories.map((category, key) => <SquadSelect 
        {...category}
        options={squads}
        key={key}
      />)}
    </DOM>
  )
}

export default ConfigureSquadsForm;