{Service} = require '../service/service'
{ApiVersion} = require '../utils/api-version'
{DataQuery} = require '../data/data-query'
{MetadataQuery} = require '../metadata/metadata-query'
{isItemScheme} = require '../metadata/metadata-type'
{MetadataDetail} = require '../metadata/metadata-detail'
{MetadataReferences} = require '../metadata/metadata-references'

itemAllowed = (resource, api) ->
  api isnt ApiVersion.v1_0_0 and
  api isnt ApiVersion.v1_0_1 and
  api isnt ApiVersion.v1_0_2 and
  ((resource isnt 'hierarchicalcodelist' and isItemScheme(resource)) or
  (api isnt ApiVersion.v1_1_0 and resource is 'hierarchicalcodelist'))

itemNeeded = (item, resource, api) ->
  item isnt 'all' and itemAllowed(resource, api)

createEntryPoint = (service) ->
  throw ReferenceError "#{service.url} is not a valid service"\
    unless service.url
  url = service.url
  url = url + '/' unless service.url.indexOf('/', service.url.length - 1) > -1
  url

createDataQuery = (query, service) ->
  url = createEntryPoint service
  url = url + "data/#{query.flow}/#{query.key}/#{query.provider}"
  url = url + "?dimensionAtObservation=#{query.obsDimension}"
  url = url + "&detail=#{query.detail}"
  if (service.api isnt ApiVersion.v1_0_0 and
  service.api isnt ApiVersion.v1_0_1 and
  service.api isnt ApiVersion.v1_0_2)
    url = url + "&includeHistory=#{query.history}"
  url = url + "&startPeriod=#{query.start}" if query.start
  url = url + "&endPeriod=#{query.end}" if query.end
  url = url + "&updatedAfter=#{query.updatedAfter}" if query.updatedAfter
  url = url + "&firstNObservations=#{query.firstNObs}" if query.firstNObs
  url = url + "&lastNObservations=#{query.lastNObs}" if query.lastNObs
  url

createShortDataQuery = (query, service) ->
  url = createEntryPoint service
  url = url + "data/#{query.flow}"
  if query.key isnt 'all' or query.provider isnt 'all'
    url = url + '/' + query.key
  if query.provider isnt 'all'
    url = url + '/' + query.provider
  params = []
  if query.obsDimension isnt 'TIME_PERIOD'
    params.push "dimensionAtObservation=#{query.obsDimension}"
  params.push "detail=#{query.detail}" if query.detail isnt 'full'
  if (service.api isnt ApiVersion.v1_0_0 and
  service.api isnt ApiVersion.v1_0_1 and
  service.api isnt ApiVersion.v1_0_2 and
  query.history)
    params.push "includeHistory=#{query.history}"
  params.push "startPeriod=#{query.start}" if query.start
  params.push "endPeriod=#{query.end}" if query.end
  params.push "updatedAfter=#{query.updatedAfter}" if query.updatedAfter
  params.push "firstNObservations=#{query.firstNObs}" if query.firstNObs
  params.push "lastNObservations=#{query.lastNObs}" if query.lastNObs
  if params.length > 0
    url = url + "?"
    url = url + params.reduceRight (x, y) -> x + "&" + y
  url

createMetadataQuery = (query, service) ->
  url = createEntryPoint service
  url = url + "#{query.resource}/#{query.agency}/#{query.id}/#{query.version}"
  if itemAllowed(query.resource, service.api)
    url = url + "/#{query.item}"
  url = url + "?detail=#{query.detail}&references=#{query.references}"
  url

createShortMetadataQuery = (q, s) ->
  u = createEntryPoint s
  u = u + "#{q.resource}"
  if (q.agency isnt "all" or q.id isnt "all" or q.version isnt "latest" or
  itemNeeded(q.item, q.resource, s.api))
    u = u + "/#{q.agency}"
  if q.id isnt "all" or q.version isnt "latest" or
  itemNeeded(q.item, q.resource, s.api)
    u = u + "/#{q.id}"
  if q.version isnt "latest" or itemNeeded(q.item, q.resource, s.api)
    u = u + "/#{q.version}"
  if itemAllowed(q.resource, s.api) and q.item isnt "all"
    u = u + "/#{q.item}"
  if (q.detail isnt MetadataDetail.FULL or
  q.references isnt MetadataReferences.NONE)
    u = u + "?"
  if q.detail isnt MetadataDetail.FULL
    u = u + "detail=#{q.detail}"
  if (q.detail isnt MetadataDetail.FULL and
  q.references isnt MetadataReferences.NONE)
    u = u + "&"
  if q.references isnt MetadataReferences.NONE
    u = u + "references=#{q.references}"
  u

generator = class Generator

  getUrl: (@query, service, skipDefaults) ->
    @service = service ? ApiVersion.LATEST
    if @query?.flow?
      if skipDefaults
        url = createShortDataQuery(@query, @service)
      else
        url = createDataQuery(@query, @service)
    else if @query?.resource?
      if skipDefaults
        url = createShortMetadataQuery(@query, @service)
      else
        url = createMetadataQuery(@query, @service)
    else
      throw TypeError "#{@query} is not a valid SDMX data or metadata query"
    url

exports.UrlGenerator = generator
