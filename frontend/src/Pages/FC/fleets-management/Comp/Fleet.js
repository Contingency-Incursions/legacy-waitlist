import { useContext, useEffect, useState, useMemo } from "react";
import { EventContext } from "../../../../contexts";
import { useApi } from "../../../../api";
import Navs from "./Navs";
import Ship from "./Ship";
import styled from "styled-components";
import { CharacterName } from "../../../../Components/EntityLinks";

const HullContainerDOM = styled.div`
  display: flex;
  flex-direction: row;
  min-height: 93px;
  // justify-content: center;
`;

const Fleet = ({ fleetBoss, fleetId, myFleet = false }) => {
  const eventContext = useContext(EventContext);
  const [ activeTab, selectTab ] = useState('on_grid');
  const [ pilots, refresh ] = useApi(`/api/v2/fleets/${fleetId}/comp`);

  useEffect(() => {
    if (!eventContext) return;

    const comp_updated = (e) => {
      let data = JSON.parse(e.data);
      if (data.id === Number(fleetId)) {
        refresh();
      }
    }

    eventContext.addEventListener("fleet_comp", comp_updated);
    return () => {
      eventContext.removeEventListener("fleet_comp", comp_updated);
    }
  }, [eventContext, fleetId, refresh])

  let fleet = useMemo(() => {
    let _fleet = {}
    pilots?.forEach(p => {
      if (!_fleet[p.hull.id]) {
        _fleet[p.hull.id] = {
          id: p.hull.id,
          name: p.hull.name,
          pilots: [{
            id: p.character.id,
            name: p.character.name,
            badges: p.position.badges,
            squad: p.position.squad,
            wing: p.position.wing,
            is_alt: p.position.is_alt
          }]
        }
      }
      else {
        _fleet[p.hull.id].pilots.push({
          id: p.character.id,
          name: p.character.name,
          badges: p.position.badges,
          squad: p.position.squad,
          wing: p.position.wing,
          is_alt: p.position.is_alt
        })
      }
    })
    return _fleet
  }, [pilots]);


  const categories = useMemo(() => {
    let _categories = {
      on_grid: { id: 'on_grid', name: 'On Grid', ships: []},
      logi: { id: 'logi', name: 'Logistics', ships: []},
      cqc: { id: 'cqc', name: 'CQC', ships: []},
      bastion: { id: 'bastion', name: 'Marauders', ships: []},
      sniper: {id: 'sniper', name: 'Sniper', ships: []},
      starter: {id: 'starter', name: 'Starter', ships: []},
      alt: {id: 'alt', name: 'Alts', ships: []},
      boxer: {id: 'boxer', name: 'Boxers', ships: []},
      off_grid: {id: 'off_grid', name: 'Off Grid', ships: []}
    }
    Object.keys(_categories).forEach(key => {
      let category = _categories[key];
      Object.keys(fleet).forEach(ship_key => {
        let ship = structuredClone(fleet[ship_key]);
        if(category.id == 'on_grid' || category.id == 'off_grid'){
          ship.pilots = ship.pilots.filter((p) => p.wing == category.name)
        } else {
          ship.pilots = ship.pilots.filter((p) => p.squad == category.id)
        }
        if(ship.pilots.length > 0){
          _categories[key].ships.push(ship);
        }
      })
    })
    return _categories;
  }, [fleet])



  let hulls = useMemo(() => {
    let _hulls = []
    if (categories[activeTab]) {
      _hulls = categories[activeTab].ships;
    }
    _hulls = _hulls.sort((a, b) => {
      if (a.pilots.length > b.pilots.length) return -1;
      if (b.pilots.length > a.pilots.length) return 1;
      return a.name.localeCompare(b.name);
    });
    return _hulls;
  }, [activeTab, categories])





  return (
    <div>
      <strong>
        { myFleet ? "Your Fleet": (
          <>
            Boss: <CharacterName {...fleetBoss} avatar={false} />
          </>
        )}

      </strong>
      <Navs
        categories={Object.values(categories)}
        activeTab={activeTab}
        tabVariant={myFleet ? 'primary' : 'secondary'}
        onClick={selectTab}
      />

      <HullContainerDOM>
      { hulls.map((hull) => {
        return <Ship
          typeId={hull.id}
          name={hull.name}
          characters={hull.pilots}
          key={hull.pilots}
        />
      })}
      </HullContainerDOM>
    </div>
  );
}

export default Fleet;
