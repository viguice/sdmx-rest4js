fs = require "fs"
{ApiVersion} = require '../utils/api-version'
{saveSettings} = require '../utils/app-settings'
{isValidEnum, createErrorMessage} = require '../utils/validators'
{DataFormat} = require '../data/data-format'
{MetadataFormat} = require '../metadata/metadata-format'
{SchemaFormat} = require '../schema/schema-format'


defaults =
  api: ApiVersion.LATEST
  external: true
  format: '*/*'

settingsFileExists = fs.existsSync("./resources/sdmxrest/settings.json")
settingshasChanged = false

isValidUrl = (url, errors) ->
  valid = typeof url is 'string' and url.match(/^https?:\/\/[^<>%$?#]*$/i)?
  errors.push "#{url} is not in a valid url" unless valid
  valid

isValidId = (id, errors) ->
  valid = typeof id is 'string' and id.match(/^[a-zA-Z0-9-_][a-zA-Z0-9-_]*$/i)?
  errors.push "#{id} is not in a valid id" unless valid
  valid

isValidService = (q) ->
  errors = []
  isValid = isValidUrl(q.url, errors) and
    isValidEnum(q.api, ApiVersion, 'versions of the SDMX RESTful API', errors)
  {isValid: isValid, errors: errors}

isValidDefaultService = (q) ->
  errors = ["The settings.json file is invalid. Fix it or delete it to reset to defaults."]
  isValid = isValidId(q.id, errors) and isValidUrl(q.url, errors) and
    isValidEnum(q.api, ApiVersion, 'versions of the SDMX RESTful API', errors)
  {isValid: isValid, errors: errors}


setSecureToDefault = (k) ->
  ###
  secure = {}
  secure[key] = service[key] for own key of service
  secure.url = secure.url.replace('http', 'https')
  secure
  ###
  indexk = services.indexOf(service["#{k}"])
  throw Error createErrorMessage(["#{k} not found in services"], 'service') unless indexk != -1
  services.splice(indexk, 1)
  services.push(service["#{k}_S"])
  #services[indexk] = service["#{k}_S"]


BIS=
  id: 'BIS'
  name: 'Bank for International Settlements'
  api: ApiVersion.v1_4_0
  url: 'https://stats.bis.org/api/v1'
  format: DataFormat.SDMX_JSON_1_0_0
  structureFormat: MetadataFormat.SDMX_JSON_1_0_0
  schemaFormat: SchemaFormat.XML_SCHEMA

ECB=
  id: 'ECB'
  name: 'European Central Bank'
  #api: ApiVersion.v1_0_2
  api: ApiVersion.v1_4_0
  #url: 'http://sdw-wsrest.ecb.europa.eu/service'
  url: 'https://data-api.ecb.europa.eu/service'
  format: DataFormat.SDMX_JSON_1_0_0_WD
  structureFormat: MetadataFormat.SDMX_ML_2_1_STRUCTURE
  schemaFormat: SchemaFormat.XML_SCHEMA

UNICEF=
  id: 'UNICEF'
  name: 'UNICEF'
  api: ApiVersion.v1_4_0
  url: 'https://sdmx.data.unicef.org/ws/public/sdmxapi/rest'
  format: DataFormat.SDMX_JSON_1_0_0
  structureFormat: MetadataFormat.SDMX_JSON_1_0_0

SDMXGR=
  id: 'SDMXGR'
  name: 'SDMX Global Registry'
  api: ApiVersion.v2_0_0
  url: 'https://registry.sdmx.org/sdmx/v2'

EUROSTAT=
  id: 'EUROSTAT'
  name: 'Eurostat'
  api: ApiVersion.v2_0_0
  url: 'https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1'

OECD=
  id: 'OECD'
  name: 'Organisation for Economic Co-operation and Development'
  api: ApiVersion.v1_0_2
  url: 'http://stats.oecd.org/SDMX-JSON'

WB=
  id: 'WB'
  name: 'World Bank'
  api: ApiVersion.v1_0_2
  url: 'http://wits.worldbank.org/API/V1/SDMX/V21/rest'

services = []
service = class Service
  @from: (opts, isPredefined) ->
    tmp_service =
      id: opts?.id
      name: opts?.name
      url: opts?.url
      api: opts?.api ? defaults.api
      format: opts?.format ? defaults.format
      structureFormat: opts?.structureFormat ? defaults.format
      schemaFormat: opts?.schemaFormat ? defaults.format
      external: opts?.external ? defaults.external
    if isPredefined
      input = isValidDefaultService tmp_service
      throw Error createErrorMessage(input.errors, 'redefined service') unless input.isValid
      services.push(tmp_service)
      if tmp_service.url.match(/^http:\/\/[^<>%$?#]*$/i)?
        secure_service =
          id: opts?.id
          name: opts?.name
          url: opts?.url.replace('http', 'https')
          api: opts?.api ? defaults.api
          format: opts?.format ? defaults.format
          structureFormat: opts?.structureFormat ? defaults.format
          schemaFormat: opts?.schemaFormat ? defaults.format
          external: opts?.external ? defaults.external
        service["#{opts.id}_S"] = secure_service
      service["#{opts.id}"] = tmp_service


    else
      input = isValidService tmp_service
      throw Error createErrorMessage(input.errors, 'service') unless input.isValid
      tmp_service


# Creates from defined services 
if !settingsFileExists
 Service.from  BIS, true
 Service.from  ECB, true
 Service.from  UNICEF, true
 Service.from  SDMXGR, true
 Service.from  EUROSTAT, true
 Service.from  OECD, true
 Service.from  WB, true
 setSecureToDefault 'OECD'

 settingshasChanged = true
else
  SERVICE_FILE = fs.readFileSync("./resources/sdmxrest/settings.json") 
  try
    settings_json = JSON.parse(SERVICE_FILE)
  catch
    throw Error createErrorMessage(["settings.json is not a valid json file"], 'default service')
  for  i in settings_json["services"]
    Service.from  i, true



if settingshasChanged
  saveSettings(services)
  
exports.Service = service
exports.services = services

