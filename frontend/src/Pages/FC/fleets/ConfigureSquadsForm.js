import { useEffect } from 'react';
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

const SquadSelect = ({ options, category, squadMappings, setSquadMappings }) => {
  const handleSelect = (evt) => { 
    setSquadMappings({
      ...squadMappings,
      [category.id]: options.find(o => o.label == evt.target.value)
    })
  };

  return (
    <FormGroup>
      <Label htmlFor={category.name}>
        {category.name}
      </Label>
      <Select value={squadMappings[category.id]?.label}  onChange={handleSelect}>
        {options?.map((squad, key) => {
          return <option value={squad.label} key={key}>{squad.label}</option>
        })}
      </Select>
    </FormGroup>
  )
}

const ConfigureSquadsForm = ({ squads, categories, squadMappings, setSquadMappings }) => {
  
  useEffect(() => {
    let mappings = {};
    for (const category of categories){
      let found_option = squads.find(option => {
        if(category.auto_detect_names !== null && category.auto_detect_names !== undefined){
          return category.auto_detect_names.find((a) => option?.label.toLowerCase().includes(a.toLowerCase()));
        } else {
          return option?.label.toLowerCase().includes(category.name.toLowerCase())
        }
      })
      mappings[category.id] = found_option;
    }
    setSquadMappings({
      ...squadMappings,
      ...mappings
    })
  }, [squads, categories, setSquadMappings]);

  return (
    <DOM>
      {categories?.map((category, key) => <SquadSelect 
        category={category}
        options={squads}
        squadMappings={squadMappings}
        setSquadMappings={setSquadMappings}
        key={key}
      />)}
    </DOM>
  )
}

export default ConfigureSquadsForm;