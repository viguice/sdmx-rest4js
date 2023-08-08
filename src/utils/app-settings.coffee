SDMXREST_VERSION="2.21.0_test"
fs = require "fs"

saveSettings = (s) ->
    if (!fs.existsSync("./resources/sdmxrest"))
        fs.mkdirSync("./resources/sdmxrest", { recursive: true})
    settings = {}
    settings["description"] = "SDMX REST API client for JavaScript"
    settings["version"] = SDMXREST_VERSION
    settings["services"] = s
    fs.writeFileSync("./resources/sdmxrest/settings.json",JSON.stringify(settings, null, 2))

exports.saveSettings = saveSettings