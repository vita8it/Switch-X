local Sea = ...
local DataModule = {} do
    DataModule.Shops = {
        ["Ability"] = {
            ["Buy Geppo"] = { "BuyHaki", "Geppo" },
            ["Buy Buso"] = { "BuyHaki", "Buso" },
            ["Buy Soru"] = { "BuyHaki", "Soru" },
            ["Buy Ken"] = { "KenTalk", "Buy" },
        },
        ["Sword"] = {
            ["Buy Katana"] = { "BuyItem", "Katana" },
            ["Buy Cutlass"] = { "BuyItem", "Cutlass" },
            ["Buy Dual Katana"] = { "BuyItem", "Dual Katana" },
            ["Buy Iron Mace"] = { "BuyItem", "Iron Mace" },
            ["Buy Triple Katana"] = { "BuyItem", "Triple Katana" },
            ["Buy Pipe"] = { "BuyItem", "Pipe" },
            ["Buy Dual-Headed Blade"] = { "BuyItem", "Dual-Headed Blade" },
            ["Buy Soul Cane"] = { "BuyItem", "Soul Cane" },
            ["Buy Bisento"] = { "BuyItem", "Bisento" },
        },
        ["Gun"] = {
            ["Buy Musket"] = { "BuyItem", "Musket" },
            ["Buy Slingshot"] = { "BuyItem", "Slingshot" },
            ["Buy Flintlock"] = { "BuyItem", "Flintlock" },
            ["Buy Refined Slingshot"] = { "BuyItem", "Refined Slingshot" },
            ["Buy Dual Flintlock"] = { "BuyItem", "Dual Flintlock" },
            ["Buy Cannon"] = { "BuyItem", "Cannon" },
            ["Buy Kabucha"] = { "BlackbeardReward", "Slingshot", "2" },
        },
        ["Accessories"] = {
            ["Buy Black Cape"] = { "BuyItem", "Black Cape" },
            ["Buy Swordsman Hat"] = { "BuyItem", "Swordsman Hat" },
            ["Buy Tomoe Ring"] = { "BuyItem", "Tomoe Ring" },
        },
        ["Race"] = {
            ["Ghoul Race"] = { "Ectoplasm", "Change", 4 },
            ["Cyborg Race"] = { "CyborgTrainer", "Buy" },
        },
    }

    DataModule.FruitIds = {
        ["rbxassetid://15124425041"] = "Rocket",
        ["rbxassetid://15123685330"] = "Spin",
        ["rbxassetid://15123613404"] = "Blade",
        ["rbxassetid://15123689268"] = "Spring",
        ["rbxassetid://15123595806"] = "Bomb",
        ["rbxassetid://15123677932"] = "Smoke",
        ["rbxassetid://15124220207"] = "Spike",
        ["rbxassetid://121545956771325"] = "Flame",
        ["rbxassetid://15123673019"] = "Sand",
        ["rbxassetid://15123618591"] = "Dark",
        ["rbxassetid://77885466312115"] = "Eagle",
        ["rbxassetid://15112600534"] = "Diamond",
        ["rbxassetid://15123640714"] = "Light",
        ["rbxassetid://15123668008"] = "Rubber",
        ["rbxassetid://15123662036"] = "Ghost",
        ["rbxassetid://15123645682"] = "Magma",
        ["rbxassetid://15123606541"] = "Quake",
        ["rbxassetid://15123643097"] = "Love",
        ["rbxassetid://15123681598"] = "Spider",
        ["rbxassetid://116828771482820"] = "Creation",
        ["rbxassetid://15123679712"] = "Sound",
        ["rbxassetid://15123654553"] = "Phoenix",
        ["rbxassetid://15123656798"] = "Portal",
        ["rbxassetid://15123670514"] = "Rumble",
        ["rbxassetid://15123652069"] = "Pain",
        ["rbxassetid://15123587371"] = "Blizzard",
        ["rbxassetid://15123633312"] = "Gravity",
        ["rbxassetid://15123648309"] = "Mammoth",
        ["rbxassetid://15694681122"] = "T-Rex",
        ["rbxassetid://15123624401"] = "Dough",
        ["rbxassetid://15123675904"] = "Shadow",
        ["rbxassetid://10773719142"] = "Venom",
        ["rbxassetid://15123616275"] = "Control",
        ["rbxassetid://11911905519"] = "Spirit",
        ["rbxassetid://15123638064"] = "Leopard",
        ["rbxassetid://15487764876"] = "Kitsune",
        ["rbxassetid://115276580506154"] = "Yeti",
        ["rbxassetid://118054805452821"] = "Gas",
        ["rbxassetid://95749033139458"] = "Dragon East"
    }

    DataModule.Islands = {
        {
            Colosseum = CFrame.new(-1517.164, 61.453, -3035.124),
            Desert = CFrame.new(1317.169, 158.484, 4463.431),
            Fountain = CFrame.new(5438.696, 418.978, 4396.387),
            Jungle = CFrame.new(-1544, 55, 76),
            ["Marine Fortress"] = CFrame.new(-4873, 142, 4328),
            ["Middle Town"] = CFrame.new(-706.579, 53.155, 1587.211),
            ["Pirate Village"] = CFrame.new(-1258, 113, 4068),
            Prison = CFrame.new(5064, 134, 735),
            Sky = CFrame.new(-4860.966, 932.238, -916.349),
            Snow = CFrame.new(1394.464, 39.045, -1321.639),
            ["Starter Island"] = CFrame.new(848, 15, 1494),
            ["Starter Marine"] = CFrame.new(-2921, 65.733, 2297),
            Underwater = CFrame.new(61162.293, 57.585, 1315.787),
            ["Upper Sky"] = CFrame.new(-5974.288, 5472.319, 2088.054),
            Volcano = CFrame.new(-5560.487, 94.99, 8472.6),
        },

        {
            Cafe = CFrame.new(-382, 74, 356),
            Colosseum = CFrame.new(-1836, 46, 1642),
            ["Dark Arena"] = CFrame.new(3948, 13, -3479),
            ["Docks 1"] = CFrame.new(-923, 8, 1810),
            ["Docks 2"] = CFrame.new(-13, 39, 2708),
            ["Docks 3"] = CFrame.new(-1944, 9, -2594),
            ["Docks 4"] = CFrame.new(-5798, 1, -5021),
            Doghouse = CFrame.new(-1984, 125, -82),
            Graveyard = CFrame.new(-5710, 126, -775),
            ["Haunted Ship"] = CFrame.new(937, 125, 32879),
            Lab = CFrame.new(-5541, 230, -5898),
            Lava = CFrame.new(-5208, 184, -5505),
            Mansion = CFrame.new(-494, 339, 593),
            Raid = CFrame.new(-6495, 95, -4897),
            Remote = CFrame.new(4766, 8, 2911),
            Skull = CFrame.new(-2956.243, 123.399, -9981.069),
            Snow = CFrame.new(1210, 429, -4663),
            ["Winter Castle"] = CFrame.new(5544.718, 60.139, -6359.089),
        },
        {
            ["Cake Land"] = CFrame.new(-2098.970, 76.395, -12128.359),
            ["Chocolate Land"] = CFrame.new(379.140, 130.206, -12720.840),
            ['Head of Great Tree'] = CFrame.new(3070, 2281, -7335),
            ["Haunted Castle"] = CFrame.new(-9515.001, 149.189, 5534.050),
            ["Hydra Arena"] = CFrame.new(5020.946, 174.086, -2011.185),
            ["Hydra Town"] = CFrame.new(5288.622, 1011.653, 392.430),
            ["Ice Cream Land"] = CFrame.new(-917.549, 63.364, -10858.696),
            ["Peanut Land"] = CFrame.new(-2037.800, 13.651, -9948.202),
            Port = CFrame.new(-342.434, 23.832, 5547.346),
            ["Sea Castle"] = CFrame.new(-5502.179, 323.671, -2863.462),
            ["Tiki Outpost"] = CFrame.new(-16456.463, 530.252, 436.232),
            ["Submerg Island"] = CFrame.new(11534, -2155, 9830),
            ["Turtle Center"] = CFrame.new(-12007.979, 339.155, -9178.580),
            ["Turtle Entrance"] = CFrame.new(-10163.965, 340.290, -8320.768),
            ["Turtle Mansion"] = CFrame.new(-12538.422, 339.394, -7817.071),
            ["Turtle Mountain"] = CFrame.new(-12856.613, 852.754, -10715.230),
        },
    }

    DataModule.Materials = {
        {
            ["Fish Tail"] = { "Fishman Warrior", "Fishman Commando" },
            ["Magma Ore"] = { "Military Soldier", "Military Spy" },
            ["GunPowder"] = { "Brute", "Pirate" },
            ["Angel Wings"] = { "God's Guard" },
            ["Scrap Metal"] = { "Brute" },
            ["Leather"] = { "Brute" }
        },
        {
            ["Ectoplasm"] = { 'Ship Steward', 'Ship Officer', 'Ship Engineer', 'Ship Deckhand' },
            ["Mystic Droplet"] = { "Water Fighter", "Sea Soldier" },
            ["Radioactive Material"] = { "Factory Staff" },
            ["Scrap Metal"] = { "Swan Pirate" },
            ["Magma Ore"] = { "Magma Ninja" },
            ["Vampire Fang"] = { "Vampire" }
        },
        {
            ["Conjured Cocoa"] = { "Cocoa Warrior", "Chocolate Bar Battler", "Sweet Thief", "Candy Rebel" },
            ["Dragon Scale"] = { "Dragon Crew Archer", "Dragon Crew Warrior" },
            ["Fish Tail"] = { "Fishman Raider", "Fishman Captain" },
            ["Mini Tusk"] = { "Mythological Pirate" },
            ["Gunpowder"] = { "Pistol Billionaire" },
            ["Scrap Metal"] = { "Jungle Pirate" },
            ["Demonic Wisp"] = { "Demonic Soul" }
        }
    }

    DataModule.Bosses = {
        {
            ["The Gorilla King"] = {
                Position = Vector3.new(-1128, 6, -451),
                Quest = { "JungleQuest", CFrame.new(-1683, 50, 173) },
                Level = 20,
            },
            ["Chef"] = {
                Position = Vector3.new(-1131, 14, 4080),
                Quest = { "BuggyQuest1", CFrame.new(-1150, 18, 3863) },
                Level = 55,
            },
            ["Yeti"] = {
                Position = Vector3.new(1185, 106, -1518),
                Quest = { "SnowQuest", CFrame.new(1399, 78, -1309) },
                Level = 105,
            },
            ["Vice Admiral"] = {
                Position = Vector3.new(-4807, 21, 4360),
                Quest = { "MarineQuest2", CFrame.new(-4695, 6, 4224), 2 },
                Level = 130,
            },
            ["Warden"] = {
                Position = Vector3.new(5230, 4, 749),
                Quest = { "ImpelQuest", CFrame.new(5322, 20, 861), 2 },
                Level = 220,
            },
            ["Magma Admiral"] = {
                Position = Vector3.new(-5694, 18, 8735),
                Quest = { "MagmaQuest", CFrame.new(-5309, 19, 8485) },
                Level = 350,
            },
            ["Fishman Lord"] = {
                Position = Vector3.new(61350, 31, 1095),
                Quest = { "FishmanQuest", CFrame.new(61402, 25, 1620) },
                Level = 425,
            },
            ["Wysper"] = {
                Position = Vector3.new(-7927, 5551, -637),
                Quest = { "SkyExp1Quest", CFrame.new(-5950, 5469, 2085) },
                Level = 500,
            },
            ["Thunder God"] = {
                Position = Vector3.new(-7751, 5607, -2315),
                Quest = { "SkyExp2Quest", CFrame.new(-7034, 5592, 1351) },
                Level = 575,
            },
            ["Cyborg"] = {
                Position = Vector3.new(6138, 10, 3939),
                Quest = { "FountainQuest", CFrame.new(5262, 76, 4087) },
                Level = 675,
            },
        },

        {
            ["Diamond"] = {
                Position = Vector3.new(-1569, 199, -31),
                Quest = { "Area1Quest", CFrame.new(-427, 73, 1835) },
                Level = 750,
            },
            ["Jeremy"] = {
                Position = Vector3.new(2316, 449, 787),
                Quest = { "Area2Quest", CFrame.new(635, 73, 919) },
                Level = 850,
            },
            ["Orbitus"] = {
                Position = Vector3.new(-2086, 73, -4208),
                Quest = { "MarineQuest3", CFrame.new(-2441, 73, -3219) },
                Level = 925,
            },
            ["Smoke Admiral"] = {
                Position = Vector3.new(-5078, 24, -5352),
                Quest = { "IceSideQuest", CFrame.new(-6061, 16, -4904) },
                Level = 1150,
            },
            ["Awakened Ice Admiral"] = {
                Position = Vector3.new(6473, 297, -6944),
                Quest = { "FrostQuest", CFrame.new(5668, 28, -6484) },
                Level = 1400,
            },
            ["Tide Keeper"] = {
                Position = Vector3.new(-3711, 77, -11469),
                Quest = { "ForgottenQuest", CFrame.new(-3056, 240, -10145) },
                Level = 1475,
            },
        },

        {
            ["Stone"] = {
                Position = Vector3.new(-1049, 40, 6791),
                Quest = { "PiratePortQuest", CFrame.new(-449, 109, 5950) },
                Level = 1550,
            },
            ["Hydra Leader"] = {
                Position = Vector3.new(5836, 1019, -83),
                Quest = { "VenomCrewQuest", CFrame.new(5214, 1004, 761) },
                Level = 1675,
            },
            ["Kilo Admiral"] = {
                Position = Vector3.new(2904, 509, -7349),
                Quest = { "MarineTreeIsland", CFrame.new(2485, 74, -6788) },
                Level = 1750,
            },
            ["Captain Elephant"] = {
                Position = Vector3.new(-13393, 319, -8423),
                Quest = { "DeepForestIsland", CFrame.new(-13233, 332, -7626) },
                Level = 1875,
            },
            ["Beautiful Pirate"] = {
                Position = Vector3.new(5370, 22, -89),
                Quest = { "DeepForestIsland2", CFrame.new(-12682, 391, -9901) },
                Level = 1950,
            },
            ["Cake Queen"] = {
                Position = Vector3.new(-710, 382, -11150),
                Quest = { "IceCreamIslandQuest", CFrame.new(-818, 66, -10964) },
                Level = 2175,
            },
        },
    }
    
    DataModule.BlackSmith = {
        ["Dark Blade"] = { ["Magma Ore"] = 10, ["Dragon Scale"] = 15, ["Dark Fragment"] = 1 },
        ["Cursed Dual Katana"] = { ["Scrap Metal"] = 60, ["Mini Tusk"] = 10, ["Demonic Wisp"] = 10 },
        ["Hallow Scythe"] = { ["Scrap Metal"] = 25, Bones = 800, ["Demonic Wisp"] = 8 },
        ["True Triple Katana"] = { Leather = 50, ["Mystic Droplet"] = 20, ["Dragon Scale"] = 5 },
        ["Spikey Trident"] = { ["Scrap Metal"] = 25, ["Conjured Cocoa"] = 8, ["Mystic Droplet"] = 5 },
        Koko = { ["Scrap Metal"] = 15, ["Vampire Fang"] = 10 },
        Tushita = { Leather = 6, ["Mini Tusk"] = 20 },
        ["Pole (2nd Form)"] = { ["Scrap Metal"] = 12, ["Mystic Droplet"] = 10, ["Fish Tail"] = 15 },
        Saddi = { Leather = 10, ["Mystic Droplet"] = 8 },
        Saber = { ["Scrap Metal"] = 10, ["Radioactive Material"] = 5, ["Magma Ore"] = 10 },
        Yama = { Leather = 6, ["Mini Tusk"] = 20 },
        ["Midnight Blade"] = { ["Scrap Metal"] = 15, Ectoplasm = 40 },
        ["Buddy Sword"] = { Leather = 25, ["Conjured Cocoa"] = 8, ["Mystic Droplet"] = 5 },
        Shisui = { Leather = 10, ["Mystic Droplet"] = 8 },
        Bisento = { ["Scrap Metal"] = 15, ["Angel Wings"] = 12, ["Magma Ore"] = 10 },
        ["Pole (1st Form)"] = { ["Scrap Metal"] = 20, ["Angel Wings"] = 10, ["Radioactive Material"] = 10 },
        Canvander = { Leather = 20, ["Dragon Scale"] = 6 },
        ["Dark Dagger"] = { ["Scrap Metal"] = 10, ["Dragon Scale"] = 8, ["Dark Fragment"] = 1 },
        Rengoku = { ["Vampire Fang"] = 8, ["Scrap Metal"] = 15, ["Magma Ore"] = 20 },
        Wando = { Leather = 10, ["Mystic Droplet"] = 8 },
        Longsword = { ["Scrap Metal"] = 10, ["Radioactive Material"] = 10 },
        Pipe = { ["Scrap Metal"] = 10, ["Fish Tail"] = 12 },
        ["Dragon Trident"] = { Leather = 10, ["Dragon Scale"] = 10 },
        Jitte = { ["Scrap Metal"] = 15, ["Vampire Fang"] = 10 },
        ["Dual-Headed Blade"] = { ["Scrap Metal"] = 10, ["Fish Tail"] = 12 },
        ["Gravity Cane"] = { ["Scrap Metal"] = 10, Meteorite = 3 },
        ["Soul Cane"] = { Leather = 20, ["Radioactive Material"] = 5 },
        ["Iron Mace"] = { Leather = 10, ["Angel Wings"] = 10 },
        ["Shark Saw"] = { Leather = 12 },
        ["Twin Hooks"] = { Leather = 20, ["Mini Tusk"] = 8, ["Fish Tail"] = 10 },
        ["Triple Katana"] = { Leather = 15, ["Scrap Metal"] = 15 },
        ["Skull Guitar"] = { ["Magma Ore"] = 10, ["Dragon Scale"] = 15, ["Dark Fragment"] = 1 },
        Kabucha = { Leather = 50, ["Dragon Scale"] = 15, ["Vampire Fang"] = 3 },
        ["Serpent Bow"] = { Meteorite = 1, ["Scrap Metal"] = 10, ["Vampire Fang"] = 10 },
        Bazooka = { ["Magma Ore"] = 10, ["Dragon Scale"] = 15, ["Dark Fragment"] = 1 },
        Cannon = { Leather = 5, ["Fish Tail"] = 5, ["Magma Ore"] = 5 },
        ["Refined Musket"] = { ["Scrap Metal"] = 10, ["Fish Tail"] = 10 },
        ["Refined Slingshot"] = { ["Scrap Metal"] = 10, ["Angel Wings"] = 10 },
        ["Bizarre Rifle"] = { Leather = 20, ["Angel Wings"] = 10, ["Magma Ore"] = 5 },
        Musket = { Leather = 5, ["Fish Tail"] = 5 },
        Flintlock = { Leather = 5, ["Magma Ore"] = 5 },
        ["Acidum Rifle"] = { Leather = 10, ["Vampire Fang"] = 8 },
    }
    
    DataModule.Codes = {
        "SUB2GAMERROBOT_EXP1",
        "starcodeheo",
        "Sub2Fer999",
        "SUB2GAMERROBOT_RESET1",
        "EASTEREXP",
        "Lightningabuse",
        "KITT_RESET",
        "Sub2UncleKizaru",
        "fudd10_v2",
        "Fudd10",
        "Bignews",
        "kittgaming",
        "Sub2CaptainMaui",
        "Enyu_is_Pro",
        "Magicbus",
        "JCWK",
        "Bluxxy",
        "TheGreatAce",
        "Sub2OfficialNoobie",
        "Sub2NoobMaster123",
        "Axiore",
        "Sub2Daigrock",
        "TantaiGaming",
        "StrawHatMaine",
    }
end

DataModule.Currently = {
    Materials = DataModule.Materials[Sea],
    Islands = DataModule.Islands[Sea],
    Bosses = DataModule.Bosses[Sea],
}

function DataModule:GetNames(Name)
    local List = {}

    for Key in self.Currently[Name] do
        List[#List + 1] = Key
    end

    return List
end

do
    DataModule.MaterialNames = DataModule:GetNames("Materials")
    DataModule.IslandNames = DataModule:GetNames("Islands")
    DataModule.BosseNames = DataModule:GetNames("Bosses")
end

return DataModule
