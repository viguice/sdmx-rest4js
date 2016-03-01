should = require('chai').should()

{MetadataDetail} = require '../src/metadata-detail.coffee'

describe 'Metadata detail', ->

  expectedDetails = [
    'full'
    'referencestubs'
    'allstubs'
  ]

  it 'should contain all expected details and only those', ->
    count = 0
    for key, value of MetadataDetail
      expectedDetails.should.contain value
      count++
    count.should.equal expectedDetails.length

  it 'should be immutable', ->
    MetadataDetail.should.be.frozen
