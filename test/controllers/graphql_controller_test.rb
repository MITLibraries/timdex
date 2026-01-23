require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  test 'graphql playground' do
    get '/playground'
    assert_equal(200, response.status)
  end

  test 'graphql ping' do
    post '/graphql', params: { query: '{ ping }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('Pong!', json['data']['ping'])
  end

  test 'graphql search' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data analytics') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data analytics") {
                                      records {
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('Data analytics and big data',
                     json['data']['search']['records'].first['title'])

        # confirm non-requested fields don't return
        assert_nil(json['data']['search']['records'].first['contentType'])
      end
    end
  end

  test 'graphql search with more returned' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data analytics') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data analytics") {
                                      records {
                                        title
                                        contentType
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('Data analytics and big data',
                     json['data']['search']['records'].first['title'])
        assert_equal('Language material',
                     json['data']['search']['records'].first['contentType'].first)
      end
    end
  end

  test 'graphql search with invalid parameters' do
    post '/graphql', params: { query: '{
                                search(searchterm: "popcorn") {
                                  records {
                                    yo
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal("Field 'yo' doesn't exist on type 'Record'",
                 json['errors'].first['message'])
  end

  test 'graphql with no query' do
    post '/graphql'
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('No query string was present',
                 json['errors'].first['message'])
  end

  test 'graphql search hits' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data analytics') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data analytics") {
                                      hits
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal(10_000, json['data']['search']['hits'])
      end
    end
  end

  test 'graphql search score' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data analytics') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data analytics") {
                                      records {
                                        score
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('32.326054', json['data']['search']['records'].first['score'])
      end
    end
  end

  test 'graphql search highlighted query terms' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data analytics highlights') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data analytics") {
                                      records {
                                        highlight {
                                          matchedField
                                          matchedPhrases
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal(
          [
            { 'matchedField' => 'citation',
              'matchedPhrases' => ['Sedkaoui, Soraya (2018): <span class="highlight">Data</span> <span class="highlight">analytics</span> and big <span class="highlight">data</span>.'] }, { 'matchedField' => 'title.exact_value', 'matchedPhrases' => ['<span class="highlight">Data analytics and big data</span>'] }, { 'matchedField' => 'title', 'matchedPhrases' => ['<span class="highlight">Data</span> <span class="highlight">analytics</span> and big <span class="highlight">data</span>'] }, { 'matchedField' => 'subjects.value', 'matchedPhrases' => ['Big <span class="highlight">data</span>'] }
          ],
          json['data']['search']['records'].first['highlight']
        )
      end
    end
  end

  test 'graphql targeted search on simple field' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search title') do
        post '/graphql', params: { query: '{
                                    search(title: "Spice it up") {
                                      records {
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal 'Spice it up!', json['data']['search']['records'].first['title']
      end
    end
  end

  test 'graphql targeted search on nested field' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search contributors') do
        post '/graphql', params: { query: '{
                                    search(contributors: "moon") {
                                      records {
                                        contributors {
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert(json['data']['search']['records'].first['contributors'].any? { |c| c.value? 'Kim, Moon H. (Moon Ho)' })
      end
    end
  end

  test 'graphql targeted search on multiple fields' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search multiple fields') do
        post '/graphql', params: { query: '{
                                    search(title: "common", contributors: "mcternan", identifiers: "163565002X") {
                                      records {
                                        title
                                        contributors {
                                          value
                                        }
                                        identifiers {
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal 'A common table : 80 recipes and stories from my shared cultures',
                     json['data']['search']['records'].first['title']
        assert(json['data']['search']['records'].first['contributors'].any? do |c|
                 c.value? 'McTernan, Cynthia Chen'
               end)
        assert(json['data']['search']['records'].first['identifiers'].any? { |i| i.value? '163565002X. (hardback)' })
      end
    end
  end

  test 'graphql geodistance search returns results' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geodistance') do
        post '/graphql', params: { query: '{
                                    search(geodistance: {
                                      distance: "100000km",
                                      latitude: 42.3596653,
                                      longitude: -71.0921384
                                    }) {
                                      hits
                                      records {
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        assert(json['data']['search']['hits'].positive?)
      end
    end
  end

  test 'graphql geodistance search fails without three required arguments' do
    post '/graphql', params: { query: '{
                                search(geodistance: {
                                  latitude: 42.3596653,
                                  longitude: -71.0921384
                                }) {
                                  hits
                                  records {
                                    title
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)

    assert(json['errors'].length.positive?)
    assert_equal(
      "Argument 'distance' on InputObject 'Geodistance' is required. Expected type String!",
      json['errors'].first['message']
    )
  end

  test 'graphql geodistance search with another argument' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geodistance with searchterm') do
        post '/graphql', params: { query: '{
                                    search(
                                      searchterm: "train stations",
                                      geodistance: {
                                        distance: "100000km",
                                        latitude: 42.3596653,
                                        longitude: -71.0921384
                                      }
                                    ) {
                                      hits
                                      records {
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        assert(json['data']['search']['hits'].positive?)
      end
    end
  end

  test 'graphql geobox search alone' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geobox') do
        post '/graphql', params: { query: '{
                                    search(geobox: {
                                      minLongitude: -73.507,
                                      minLatitude: 41.239,
                                      maxLongitude: -69.928,
                                      maxLatitude: 42.886
                                    }) {
                                      hits
                                      records {
                                        title
                                        locations {
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        assert(json['data']['search']['hits'].positive?)
      end
    end
  end

  test 'graphql geobox search required arguments' do
    post '/graphql', params: { query: '{
                                search(geobox: {
                                  minLongitude: -73.507,
                                  minLatitude: 41.239,
                                  maxLongitude: -69.928,
                                }
                                source: "MIT GIS Resources") {
                                  hits
                                  records {
                                    title
                                    locations {
                                      geoshape
                                      kind
                                      value
                                    }
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)

    assert(json['errors'].length.positive?)
    assert_equal(
      "Argument 'maxLatitude' on InputObject 'Geobox' is required. Expected type Float!",
      json['errors'].first['message']
    )
  end

  test 'graphql geobox search longitude order matters' do
    # This is fragile to our collection having an equal number of records in both hemispheres.
    eastern_hits = 0
    western_hits = 0
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geobox hemispheres') do
        post '/graphql', params: { query: '{
                                    search(geobox: {
                                      minLongitude: 0,
                                      minLatitude: -90,
                                      maxLongitude: 180,
                                      maxLatitude: 90
                                    },
                                    source: "MIT GIS Resources") {
                                      hits
                                      records {
                                        title
                                        locations {
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        eastern_hits = json['data']['search']['hits']
        assert(eastern_hits.positive?)

        post '/graphql', params: { query: '{
                                    search(geobox: {
                                      minLongitude: 180,
                                      minLatitude: -90,
                                      maxLongitude: 0,
                                      maxLatitude: 90
                                    },
                                    source: "MIT GIS Resources") {
                                      hits
                                      records {
                                        title
                                        locations {
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        western_hits = json['data']['search']['hits']
        assert(western_hits.positive?)
      end
    end
    refute_equal(eastern_hits, western_hits)
  end

  test 'graphql geobox search with keyword search' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geobox with keyword') do
        post '/graphql', params: { query: '{
                                    search(
                                      searchterm: "train stations",
                                      geobox: {
                                        minLongitude: -73.507,
                                        minLatitude: 41.239,
                                        maxLongitude: -69.928,
                                        maxLatitude: 42.886
                                      }
                                    ) {
                                      hits
                                      records {
                                        title
                                        locations {
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        assert(json['data']['search']['hits'].positive?)
      end
    end
  end

  test 'graphql geobox search with geodistance search' do
    # This is not a recommended way to work, but it does function.
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geobox with geodistance') do
        post '/graphql', params: { query: '{
                                    search(
                                      geodistance: {
                                        distance: "1km",
                                        latitude: 0,
                                        longitude: 0
                                      },
                                      geobox: {
                                        minLongitude: -73.507,
                                        minLatitude: 41.239,
                                        maxLongitude: -69.928,
                                        maxLatitude: 42.886
                                      }
                                    ) {
                                      hits
                                      records {
                                        title
                                        locations {
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_nil(json['errors'])
        assert(json['data']['search']['hits'].positive?)
      end
    end
  end

  test 'graphql search aggregations' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search data') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "data") {
                                      aggregations {
                                        source {
                                          key
                                          docCount
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('mit alma',
                     json['data']['search']['aggregations']['source']
                     .first['key'])
        assert_equal(208_361,
                     json['data']['search']['aggregations']['source']
                     .first['docCount'])
      end
    end
  end

  test 'graphql search with source filter applied' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search a only alma') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "a",
                                      sourceFilter: "MIT Alma") {
                                      hits
                                      aggregations {
                                        source {
                                          key
                                          docCount
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('mit alma',
                     json['data']['search']['aggregations']['source']
                     .first['key'])
        assert_equal(1_636_808,
                     json['data']['search']['aggregations']['source']
                     .first['docCount'])
      end
    end
  end

  test 'graphql search with deprecated source string applied' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search a only alma deprecated') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "a",
                                      source: "MIT Alma") {
                                      hits
                                      aggregations {
                                        source {
                                          key
                                          docCount
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('mit alma',
                     json['data']['search']['aggregations']['source']
                     .first['key'])
        assert_equal(1_636_808,
                     json['data']['search']['aggregations']['source']
                     .first['docCount'])
      end
    end
  end

  test 'graphql deprecated datePublished does not error when no dates returned' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql datePublished does not error when no dates returned') do
        post '/graphql', params: { query: '{
                                    recordId(id: "dspace:1721.1-2789") {
                                      publicationDate
                                      source
                                      sourceLink
                                      title
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal('DSpace@MIT', json['data']['recordId']['source'])
        assert_nil(json['data']['recordId']['dates'])
      end
    end
  end

  test 'graphql search with multiple subjects applied' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql search multiple subjects') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "space",
                                          subjectsFilter: ["Astrophysics",
                                          "Observations, Astronomical"]) {
                                      hits
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal(225, json['data']['search']['hits'])
      end
    end
  end

  test 'graphql search with invalid filter applied' do
    post '/graphql', params: { query: '{
                                search(searchterm: "wright",
                                  fake: "mit archivesspace") {
                                  hits
                                  aggregations {
                                    source {
                                      key
                                      docCount
                                    }
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert(json['errors'].first['message'].present?)
    assert_equal("Field 'search' doesn't accept argument 'fake'",
                 json['errors'].first['message'])
  end

  test 'graphql valid filters can result in no results' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql legal filters can result in no results') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "wright",
                                      subjectsFilter: ["fake filter value"]) {
                                      hits
                                      aggregations {
                                        source {
                                          key
                                          docCount
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal(0, json['data']['search']['hits'])
      end
    end
  end

  test 'graphql retrieve' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql retrieve') do
        post '/graphql', params: { query: '{
                                    recordId(id: "alma:9935129973406761") {
                                      timdexRecordId
                                      title
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert(json['data']['recordId']['title'].start_with?('Space Storms and Space Weather Hazards'))
        assert_equal('alma:9935129973406761', json['data']['recordId']['timdexRecordId'])

        # confirm non-requested fields don't return
        assert_nil(json['data']['recordId']['literaryForm'])
      end
    end
  end

  test 'graphql retrieve with not found recordid' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql retrieve not found') do
        post '/graphql', params: { query: '{
                                    recordId(id: "totallylegitrecordid") {
                                      timdexRecordId
                                      title
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_nil(json['data'])
        assert_equal("Record 'totallylegitrecordid' not found", json['errors'].first['message'])
      end
    end
  end

  test 'graphql holding location is not required' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql location') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "bermuda", index: "geo") {
                                      records {
                                        holdings {
                                          location
                                        }
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        # TIMDEX will throw an error for non-nullable subfields if the parent field is null, so we only need to find null
        # values of 'holdings' to test this.
        assert json['data']['search']['records'].map { |record| record['holdings'].nil? }.any?
        refute json['errors'].present?
      end
    end
  end

  test 'graphql can retrieve geolocation information' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql geolocation') do
        post '/graphql', params: { query: '{
                                    search(searchterm: "train stations") {
                                      records {
                                        locations {
                                          geopoint
                                          geoshape
                                          kind
                                          value
                                        }
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)

        assert_not json['errors'].present?
        assert_equal(
          json['data']['search']['records'].first['locations'][0].keys.sort,
          %w[geopoint geoshape value kind].sort
        )
      end
    end
  end

  test 'graphql retrieve invalid field' do
    post '/graphql', params: { query: 'recordId(id: "stuff") {
                                stuff
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert(json['errors'].first['message'].present?)
  end

  test 'graphql filter multiple sources' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql filter multiple sources') do
        # no filters to return all sources. used later to test filters return less than the total.
        post '/graphql', params: { query:
          '{
            search(searchterm: "data") {
              hits
              aggregations {
                source {
                  key
                  docCount
                }
              }
            }
          }' }

        json = JSON.parse(response.body)
        initial_source_array = json['data']['search']['aggregations']['source']

        # filtering to 2 sources returns 2 sources
        post '/graphql', params: { query:
          '{
            search(searchterm: "data", sourceFilter: ["Zenodo", "DSpace@MIT"]) {
              hits
              aggregations {
                source {
                  key
                  docCount
                }
              }
            }
          }' }
        assert_equal(200, response.status)

        json = JSON.parse(response.body)
        filtered_source_array = json['data']['search']['aggregations']['source']

        assert(initial_source_array.count > filtered_source_array.count)
        assert_equal(2, filtered_source_array.count)

        expected_sources = ['zenodo', 'dspace@mit']
        actual_sources = filtered_source_array.map { |source| source['key'] }
        assert_equal(expected_sources.sort, actual_sources.sort)
      end
    end
  end

  test 'graphql filter single source' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql filter single source') do
        # no filters to return all sources. used later to test filters return less than the total.
        post '/graphql', params: { query:
          '{
            search(searchterm: "data") {
              hits
              aggregations {
                source {
                  key
                  docCount
                }
              }
            }
          }' }

        json = JSON.parse(response.body)
        initial_source_array = json['data']['search']['aggregations']['source']

        # filtering to 1 sources returns 1 source
        post '/graphql', params: { query:
          '{
            search(searchterm: "data", sourceFilter: ["DSpace@MIT"]) {
              hits
              aggregations {
                source {
                  key
                  docCount
                }
              }
            }
          }' }
        assert_equal(200, response.status)

        json = JSON.parse(response.body)
        filtered_source_array = json['data']['search']['aggregations']['source']

        assert(initial_source_array.count > filtered_source_array.count)
        assert_equal(1, filtered_source_array.count)

        expected_sources = ['dspace@mit']
        actual_sources = filtered_source_array.map { |source| source['key'] }
        assert_equal(expected_sources, actual_sources)
      end
    end
  end

  test 'graphql can retrieve a record from a default index' do
    # fragile test: specific item expected in default index
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql retrieve from default index') do
        post '/graphql', params: { query:
          '{
            recordId(id: "dspace:1721.1-44968") {
              timdexRecordId
              title
            }
          }' }

        json = JSON.parse(response.body)
        assert_equal('dspace:1721.1-44968', json['data']['recordId']['timdexRecordId'])
      end
    end
  end

  test 'graphql can retrieve a record from a specified index' do
    # fragile test: specific item expected in specified index
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql retrieve from geo index') do
        post '/graphql', params: { query:
          '{
            recordId(id: "gismit:BD_A8GNS_2003", index: "geo") {
              timdexRecordId
              title
            }
          }' }

        json = JSON.parse(response.body)
        assert_equal('gismit:BD_A8GNS_2003', json['data']['recordId']['timdexRecordId'])
      end
    end
  end

  test 'graphql can apply multi-value filters' do
    # fragile test: filter data required to have at least 2 records with both
    # `dataset` and `still image` contentTypes
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql apply multiple content types filters') do
        post '/graphql', params: { query:
          '{
            search(index: "rdi*", contentTypeFilter:["dataset"]) {
              hits
              aggregations {
                contentType {
                  key
                  docCount
                }
              }
            }
          }' }

        json_dataset = JSON.parse(response.body)
        initial_hits_count = json_dataset['data']['search']['hits']
        initial_still_images_count = json_dataset['data']['search']['aggregations']['contentType'].find do |x|
                                       x['key'] == 'still image'
                                     end ['docCount']

        post '/graphql', params: { query:
          '{
            search(index: "rdi*", contentTypeFilter:["dataset", "still image"]) {
              hits
              aggregations {
                contentType {
                  key
                  docCount
                }
              }
            }
          }' }

        json_dataset_still_image = JSON.parse(response.body)
        final_hits_count = json_dataset_still_image['data']['search']['hits']

        assert(initial_hits_count > final_hits_count)
        assert_equal(final_hits_count, initial_still_images_count)
      end
    end
  end

  test 'graphql can apply places filter' do
    VCR.use_cassette('opensearch init') do
      VCR.use_cassette('graphql places filter') do
        post '/graphql', params: { query:
          '{
            search(index: "geo") {
              hits
              aggregations {
                places {
                  key
                  docCount
                }
              }
            }
          }' }

        json_data = JSON.parse(response.body)
        initial_hits_count = json_data['data']['search']['hits']

        post '/graphql', params: { query:
          '{
            search(index: "geo", placesFilter:["massachusetts"]) {
              hits
              aggregations {
                places {
                  key
                  docCount
                }
              }
            }
          }' }

        json_data = JSON.parse(response.body)
        filtered_hits_count = json_data['data']['search']['hits']

        assert(initial_hits_count > 0)
        assert(filtered_hits_count > 0)
        assert(filtered_hits_count < initial_hits_count)
      end
    end
  end

  test 'graphql search respects perPage argument' do
    VCR.use_cassette('opensearch_init') do
      VCR.use_cassette('graphql_search_per_page_5', match_requests_on: [:method, :uri]) do
        post '/graphql', params: { query: '{
                                    search(perPage:5) {
                                      hits
                                      records {
                                        title
                                      }
                                    }
                                  }' }
        assert_equal(200, response.status)
        json = JSON.parse(response.body)
        assert_equal(5, json['data']['search']['records'].count)
        assert_equal(100, json['data']['search']['hits'])
      end
    end
  end
end
