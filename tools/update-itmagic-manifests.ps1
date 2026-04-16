Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$repoRoot = Split-Path -Parent $PSScriptRoot
$packagesRoot = Join-Path $repoRoot "packages\ITsMagic"

$packConfigs = @{
    "https://sketchfab.com/3d-models/factory-props-ee08d29bc6cd411e845e50903e4060ca" = @{
        PackTitle = "Factory Props"
        Author = "Thomas_Crozelon"
        PackTags = @("game-ready", "unity")
        Tail = "It is suited for industrial scenes, service areas, utility spaces and environment dressing in real-time projects, using the original pack's 4K maps."
    }
    "https://sketchfab.com/3d-models/brimstone-props-c8dc1ea25ff74ea4b3ebc3dcd7540e89" = @{
        PackTitle = "Brimstone Props"
        Author = "CtrlLight"
        PackTags = @("realistic", "game-ready")
        Tail = "It fits interior props, room dressing and environmental storytelling scenes inspired by the original Brimstone project."
    }
    "https://sketchfab.com/3d-models/street-asset-pack-f3eb47d02e2e4ab290e66752fa354b48" = @{
        PackTitle = "Street Asset Pack"
        Author = "vmatthew"
        PackTags = @("street", "urban")
        Tail = "It fits sidewalks, roadwork, alleys and urban environment dressing, based on assets created in Blender and Substance 3D Painter."
    }
    "https://sketchfab.com/3d-models/tropical-plants-pack-m02p-2f093afb792742438f0f7ba7eaab90f0" = @{
        PackTitle = "Tropical Plants Pack M02P"
        Author = "MozzarellaARC"
        PackTags = @("tropical", "pbr", "unreal-engine")
        Tail = "It fits tropical gardens, lush exterior scenes, architectural visualization and Unreal Engine environments, using the original pack's PBR workflow."
    }
    "https://sketchfab.com/3d-models/furniture-pack-low-poly-game-ready-1bfa5e4878eb4a9f83f3cbec80022b5d" = @{
        PackTitle = "Furniture Pack | Low-Poly | Game-Ready"
        Author = "kEam"
        PackTags = @("low-poly", "game-ready")
        Tail = "It is suited for room dressing, home interiors and stylized real-time environments from the original low-poly game-ready furniture collection."
    }
    "https://sketchfab.com/3d-models/barrel-pack-0c6f87ea51234a328b106ee220827595" = @{
        PackTitle = "Barrel Pack"
        Author = "vmatthew"
        PackTags = @("game-ready")
        Tail = "It fits prop dressing, storage scenes and real-time environment composition, based on the pack's improved textures and higher-poly treatment."
    }
    "https://sketchfab.com/3d-models/medieval-props-e69777fa47244434b337488b97cecd0e" = @{
        PackTitle = "Medieval Props"
        Author = "Daniel Vicente"
        PackTags = @("medieval", "game-ready")
        Tail = "It fits modular medieval city scenes, village environments, courtyards and historical set dressing."
    }
    "https://sketchfab.com/3d-models/old-concete-building-pack-lowpoly-6d070fcc86b0430dadf53da67545c6f3" = @{
        PackTitle = "Old Concete Building Pack | Lowpoly"
        Author = "Frid.blend"
        PackTags = @("low-poly", "abandoned")
        Tail = "It fits abandoned urban environments and modular city scenes, based on the original FBX asset with 4K textures."
    }
    "https://sketchfab.com/3d-models/old-building-pack-lowpoly-081eccb97be8429c83b2e9fb407727e7" = @{
        PackTitle = "Old Building Pack | Lowpoly"
        Author = "Frid.blend"
        PackTags = @("low-poly", "abandoned")
        Tail = "It fits urban backdrops and abandoned district scenes, based on the original FBX asset and basecolor texture workflow."
    }
}

$primaryTagMap = @{
    "bottle" = "glass-bottle"
    "broken-bottle" = "broken-bottle"
    "broken-coffee-cup" = "broken-cup"
    "coffee-cup" = "coffee-cup"
    "coffee-saucer" = "coffee-saucer"
    "concrete-barrier" = "concrete-barrier"
    "digit-slider" = "digit-slider"
    "door-beam" = "door-frame"
    "fire-extinguisher" = "fire-extinguisher"
    "glass-bottle" = "glass-bottle"
    "hydrant" = "fire-hydrant"
    "large-lampshade" = "lampshade"
    "light-bulb" = "light-bulb"
    "light-reflector" = "work-light"
    "metal-bar" = "metal-bar"
    "metal-barrel" = "metal-barrel"
    "metal-barrier" = "metal-barrier"
    "metal-pipe" = "metal-pipe"
    "monstera-deliciosa-plant" = "monstera"
    "old-building" = "old-building"
    "old-concrete-building" = "concrete-building"
    "opened-box" = "opened-box"
    "pamps-shade" = "table-lamp"
    "plataform-transport-cart" = "platform-cart"
    "screw-driver" = "screwdriver"
    "small-water-source" = "covered-well"
    "square-towel" = "tablecloth"
    "table-chandelier" = "candelabra"
    "traffic-beacon" = "traffic-bollard"
    "traffic-cone" = "traffic-cone"
    "traffic-sign" = "traffic-sign"
    "ventilation-grid" = "ventilation-grid"
    "wardobre" = "wardrobe"
    "water-source" = "fountain"
    "wet-floor-board" = "warning-sign"
    "wheel-barrow" = "wheelbarrow"
}

$labelMap = @{
    "adhesive-tape" = "adhesive tape"
    "banana-tree" = "banana tree"
    "bathroom-sink" = "bathroom sink"
    "broken-bottle" = "broken bottle"
    "broken-coffee-cup" = "broken coffee cup"
    "cardboard-box" = "cardboard box"
    "claw-hammer" = "claw hammer"
    "coffee-cup" = "coffee cup"
    "coffee-saucer" = "coffee saucer"
    "concrete-barrier" = "concrete barrier"
    "digit-slider" = "combination digit slider"
    "door-beam" = "door frame"
    "engine-room" = "engine room module"
    "fire-extinguisher" = "fire extinguisher"
    "garbage-bag" = "garbage bag"
    "glass-bottle" = "glass bottle"
    "human-skull" = "human skull"
    "large-lampshade" = "large lampshade"
    "light-bulb" = "light bulb"
    "light-reflector" = "portable work light"
    "luggage-cart" = "luggage cart"
    "metal-bar" = "metal bar"
    "metal-barrel" = "metal barrel"
    "metal-barrier" = "metal barrier"
    "metal-pipe" = "metal pipe"
    "metal-table" = "metal table"
    "monstera-deliciosa-plant" = "monstera plant"
    "old-building" = "old building"
    "old-concrete-building" = "old concrete building"
    "opened-box" = "opened box"
    "palm-tree" = "palm tree"
    "pamps-shade" = "table lamp"
    "paper-box" = "paper box"
    "plastic-tarp" = "plastic tarp"
    "plataform-transport-cart" = "platform cart"
    "screw-driver" = "screwdriver"
    "small-tree" = "small tree"
    "small-water-source" = "covered well"
    "smoking-pipe" = "smoking pipe"
    "square-towel" = "tablecloth"
    "table-chandelier" = "table candelabra"
    "traffic-beacon" = "traffic bollard"
    "traffic-cone" = "traffic cone"
    "traffic-sign" = "traffic sign"
    "ventilation-grid" = "ventilation grid"
    "wardobre" = "wardrobe"
    "water-source" = "stone fountain"
    "wet-floor-board" = "warning sign"
    "wheel-barrow" = "wheelbarrow"
    "wooden-board" = "wooden board"
    "wooden-box" = "wooden box"
    "wooden-crate" = "wooden crate"
    "wooden-pallet" = "wooden pallet"
    "wooden-tub" = "wooden tub"
}

$extraTagMap = @{
    "adhesive-tape" = @("tape", "tooling", "utility")
    "ashtray" = @("decor", "interior")
    "banana-tree" = @("tree", "plant", "vegetation")
    "barrel" = @("container", "storage", "industrial")
    "bathroom-sink" = @("plumbing", "bathroom", "interior")
    "books" = @("decor", "interior")
    "bottle" = @("glass", "street-prop")
    "box" = @("container", "storage")
    "broken-bottle" = @("glass", "debris", "street-prop")
    "broken-coffee-cup" = @("debris", "tableware", "street-prop")
    "bucket" = @("container", "utility")
    "cabinet" = @("furniture", "storage", "interior")
    "cardboard-box" = @("container", "storage", "packaging")
    "chair" = @("furniture", "seating", "interior")
    "claw-hammer" = @("tool", "workshop", "utility")
    "coffee-cup" = @("tableware", "kitchen")
    "coffee-saucer" = @("tableware", "kitchen", "interior")
    "concrete-barrier" = @("barrier", "roadwork", "safety")
    "cone" = @("roadwork", "safety")
    "container" = @("storage", "industrial", "shipping")
    "digit-slider" = @("mechanism", "puzzle", "interior")
    "door" = @("interior", "entryway")
    "door-beam" = @("structural", "entryway", "interior")
    "dresser" = @("furniture", "storage", "interior")
    "engine-room" = @("machinery", "industrial", "environment")
    "fern" = @("plant", "vegetation", "interior")
    "fire-extinguisher" = @("safety", "emergency", "utility")
    "garbage-bag" = @("trash", "waste", "street-prop")
    "glass-bottle" = @("glass", "container", "interior")
    "glue" = @("adhesive", "tooling", "utility")
    "house" = @("building", "architecture", "residential")
    "human-skull" = @("decor", "macabre", "interior")
    "hydrant" = @("utility", "street-prop", "emergency")
    "ladder" = @("access", "utility")
    "lake" = @("water", "environment", "terrain")
    "large-lampshade" = @("lighting", "decor", "interior")
    "light-bulb" = @("lighting", "electrical", "interior")
    "light-reflector" = @("lighting", "utility", "workshop")
    "luggage-cart" = @("transport", "hospitality", "interior")
    "metal-bar" = @("construction", "industrial", "material")
    "metal-barrel" = @("container", "storage", "industrial")
    "metal-barrier" = @("barrier", "roadwork", "safety")
    "metal-pipe" = @("pipe", "industrial", "construction")
    "metal-table" = @("furniture", "industrial", "interior")
    "mirror" = @("decor", "interior", "bathroom")
    "monstera-deliciosa-plant" = @("plant", "vegetation", "interior")
    "mug" = @("tableware", "kitchen", "interior")
    "old-building" = @("architecture", "building", "urban")
    "old-concrete-building" = @("architecture", "building", "urban")
    "opened-box" = @("container", "storage", "packaging")
    "palm-tree" = @("tree", "plant", "vegetation")
    "pamps-shade" = @("lighting", "decor", "interior")
    "paper-box" = @("container", "storage", "packaging")
    "plastic-tarp" = @("covering", "utility", "industrial")
    "plataform-transport-cart" = @("transport", "warehouse", "utility")
    "pliers" = @("tool", "workshop", "utility")
    "sack" = @("bag", "storage", "utility")
    "screw-driver" = @("tool", "workshop", "utility")
    "shelf" = @("furniture", "storage", "interior")
    "small-tree" = @("tree", "vegetation", "nature")
    "small-water-source" = @("water-feature", "medieval", "environment")
    "smoking-pipe" = @("decor", "interior", "tabletop")
    "square-towel" = @("fabric", "decor", "interior")
    "suitcase" = @("luggage", "travel", "interior")
    "table" = @("furniture", "interior", "surface")
    "table-chandelier" = @("lighting", "decor", "tabletop")
    "telescope" = @("instrument", "decor", "interior")
    "tent" = @("shelter", "camp", "medieval")
    "toilet" = @("bathroom", "plumbing", "interior")
    "traffic-beacon" = @("roadwork", "safety", "street-prop")
    "traffic-cone" = @("roadwork", "safety", "street-prop")
    "traffic-sign" = @("signage", "roadwork", "safety")
    "tree" = @("tree", "vegetation", "nature")
    "vase" = @("decor", "interior", "tabletop")
    "ventilation-grid" = @("utility", "interior", "architecture")
    "wardobre" = @("furniture", "storage", "interior")
    "water-source" = @("water-feature", "medieval", "environment")
    "wet-floor-board" = @("safety", "signage", "interior")
    "wheel-barrow" = @("transport", "utility", "garden")
    "wooden-board" = @("material", "construction", "wood")
    "wooden-box" = @("container", "storage", "wood")
    "wooden-crate" = @("container", "storage", "wood")
    "wooden-pallet" = @("storage", "warehouse", "wood")
    "wooden-tub" = @("container", "wood", "utility")
}

function Decode-Base64([string]$text) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($text))
}

function Encode-Base64([string]$text) {
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text))
}

function Get-CanonicalName([string]$packageName) {
    $canonical = $packageName
    $canonical = $canonical -replace "-\d+variant$", ""
    $canonical = $canonical -replace "-variant-\d+$", ""
    $canonical = $canonical -replace "-variant$", ""
    $canonical = $canonical -replace "-\d+$", ""
    return $canonical
}

function Get-PrimaryTag([string]$canonicalName) {
    if ($primaryTagMap.ContainsKey($canonicalName)) {
        return $primaryTagMap[$canonicalName]
    }
    return $canonicalName
}

function Normalize-Tag([string]$tag) {
    $normalized = $tag.ToLowerInvariant() -replace "-", "_"
    $normalized = $normalized -replace "[^a-z0-9_]", "_"
    $normalized = $normalized -replace "_{2,}", "_"
    return $normalized.Trim("_")
}

function Get-DisplayLabel([string]$canonicalName) {
    if ($labelMap.ContainsKey($canonicalName)) {
        return $labelMap[$canonicalName]
    }
    return ($canonicalName -replace "-", " ")
}

function Get-Description([string]$packageName, [string]$canonicalName, [hashtable]$packConfig) {
    $label = Get-DisplayLabel $canonicalName
    $lead = if ($packageName -ne $canonicalName) {
        "This package provides a variant of the $label asset"
    } else {
        "This package provides the $label asset"
    }
    return "$lead extracted from the `"$($packConfig.PackTitle)`" Sketchfab pack by $($packConfig.Author). $($packConfig.Tail)"
}

function Get-Tags([string]$packageName, [string]$canonicalName, [hashtable]$packConfig) {
    $tags = New-Object System.Collections.Generic.List[string]
    $tags.Add((Get-PrimaryTag $canonicalName))

    if ($extraTagMap.ContainsKey($canonicalName)) {
        foreach ($tag in $extraTagMap[$canonicalName]) {
            $tags.Add($tag)
        }
    }

    foreach ($tag in $packConfig.PackTags) {
        $tags.Add($tag)
    }

    if ($packageName -ne $canonicalName) {
        $tags.Add("variant")
    }

    $unique = [System.Collections.Generic.List[string]]::new()
    foreach ($tag in $tags) {
        $normalizedTag = Normalize-Tag $tag
        if (-not [string]::IsNullOrWhiteSpace($normalizedTag) -and -not $unique.Contains($normalizedTag)) {
            $unique.Add($normalizedTag)
        }
    }

    return ($unique | Select-Object -First 8)
}

$updated = 0
$manifests = Get-ChildItem -Path $packagesRoot -Recurse -Filter "manifest.json"

foreach ($manifestPath in $manifests) {
    $manifest = Get-Content $manifestPath.FullName -Raw | ConvertFrom-Json
    if ($manifest.isTemplate) {
        continue
    }

    $packageName = Split-Path $manifestPath.DirectoryName -Leaf
    $canonicalName = Get-CanonicalName $packageName
    $licenseUrl = Decode-Base64 $manifest.licenseB64

    if (-not $packConfigs.ContainsKey($licenseUrl)) {
        throw "Unknown Sketchfab URL for package '$packageName': $licenseUrl"
    }

    $packConfig = $packConfigs[$licenseUrl]
    $newDescription = Get-Description $packageName $canonicalName $packConfig
    $newTags = (Get-Tags $packageName $canonicalName $packConfig) -join ","

    $updatedManifest = [ordered]@{
        titleB64 = $manifest.titleB64
        descriptionB64 = Encode-Base64 $newDescription
        tags = $newTags
        version = $manifest.version
        appMajorVersion = $manifest.appMajorVersion
        repositoryURL = $manifest.repositoryURL
        isTemplate = $manifest.isTemplate
        date = $manifest.date
        thumbnail = $manifest.thumbnail
        images = $manifest.images
        licenseB64 = $manifest.licenseB64
        repivot = $manifest.repivot
    }

    $json = $updatedManifest | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($manifestPath.FullName, $json + [Environment]::NewLine, $utf8NoBom)
    $updated++
}

Write-Output "Updated $updated manifests."
