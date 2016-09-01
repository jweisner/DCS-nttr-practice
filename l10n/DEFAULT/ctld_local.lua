-- Simulated Sling load configuration

ctld.minimumHoverHeight = 7.5 -- Lowest allowable height for crate hover
ctld.maximumHoverHeight = 12.0 -- Highest allowable height for crate hover
ctld.maxDistanceFromCrate = 5.5 -- Maximum distance from from crate for hover
ctld.hoverTime = 5 -- Time to hold hover above a crate for loading in seconds

ctld.enabledFOBBuilding = true -- if true, you can load a crate INTO a C-130 than when unpacked creates a Forward Operating Base (FOB) which is a new place to spawn (crates) and carry crates from
-- In future i'd like it to be a FARP but so far that seems impossible...
-- You can also enable troop Pickup at FOBS

ctld.cratesRequiredForFOB = 1 -- The amount of crates required to build a FOB. Once built, helis can spawn crates at this outpost to be carried and deployed in another area.
-- The large crates can only be loaded and dropped by large aircraft, like the C-130 and listed in ctld.vehicleTransportEnabled
-- Small FOB crates can be moved by helicopter. The FOB will require ctld.cratesRequiredForFOB larges crates and small crates are 1/3 of a large fob crate
-- To build the FOB entirely out of small crates you will need ctld.cratesRequiredForFOB * 3

-- ************** ADD-ON SPAWNABLE CRATES ******************
-- Weights must be unique as we use the weight to change the cargo to the correct unit
-- when we unpack
--
do
    local _addCrates = {
        ["AA Crates"] = {
            { weight = 421, desc = "AAA Vulcan", unit = "Vulcan", side = 2, cratesRequired = 1 },
            { weight = 422, desc = "AAA Gepard", unit = "Gepard", side = 2, cratesRequired = 2 },
            { weight = 423, desc = "AAA ZU-23", unit = "Ural-375 ZU-23", side = 1, cratesRequired = 1 },
            { weight = 424, desc = "AAA ZSU-23-4 Shilka", unit = "ZSU-23-4 Shilka", side = 1, cratesRequired = 2 },
        },
    }

    -- add extra crate options
    for _subMenuName, _crates in pairs(_addCrates) do

        for _, _crate in pairs(_crates) do
            -- add crate to the menu table
            table.insert(ctld.spawnableCrates[_subMenuName], _crate)
            -- add crate to the lookup table
            ctld.crateLookupTable[tostring(_crate.weight)] = _crate
        end
    end
end