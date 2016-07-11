Helper = require('hubot-test-helper')
chai = require 'chai'
auth = require 'hubot-auth'

Promise = require('bluebird')
co = require('co')
expect = chai.expect

helper = new Helper('../src/bosun.coffee')

http = require 'http'

process.env.EXPRESS_PORT = 18080

wait_time = 100

describe 'bosun', ->
  beforeEach ->
    process.env.HUBOT_BOSUN_HOST = "http://localhost:18070"
    process.env.HUBOT_BOSUN_ROLE = "bosun"
    process.env.HUBOT_BOSUN_SLACK = "no"
    process.env.HUBOT_BOSUN_LOG_LEVEL = "error"
    process.env.HUBOT_BOSUN_RELATIVE_TIME = "no"

    @room = helper.createRoom()
    @room.robot.auth = new MockAuth

    @bosun = mock_bosun()
    @bosun.listen(18070, "127.0.0.1")


  afterEach ->
    @room.destroy()
    @bosun.close()

  context "incidents", ->

    context "show incidents", ->

      context "show incidents for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot show open bosun incidents'
            yield new Promise.delay(wait_time)

        it 'show bosun incidents', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot show open bosun incidents']
            ['hubot', '@alice Retrieving Bosun incidents ...']
            ['hubot', '@alice Yippie. Done.']
            ['hubot', '@alice So, there are currently 2 open incidents in Bosun.']
            ['hubot', '@alice 750 is warning: warning: <no value>.']
            ['hubot', '@alice 759 is normal: warning: <no value>.']
          ]

       context "Fail if unauthorized", ->

        it 'show open bosun incidents for unauthorized bob', ->
          @room.user.say('bob', '@hubot show open bosun incidents').then =>
            expect(@room.messages).to.eql [
              ['bob', '@hubot show open bosun incidents']
              ['hubot', "@bob Sorry, you're not allowed to do that. You need the 'bosun' role."]
            ]

    context "ack and close incidents", ->

      context "ack single incident", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot ack bosun incident 123 because it is normal again.'
            yield new Promise.delay(wait_time)

        it 'ack bosun alarm', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot ack bosun incident 123 because it is normal again.']
            ['hubot', '@alice Trying to ack Bosun incident 123 ...']
            ['hubot', '@alice Yippie. Done.']
          ]

      context "Ack (with capital 'A') single incident", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot Ack bosun incident 123 because it is normal again.'
            yield new Promise.delay(wait_time)

        it 'ack bosun alarm', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot Ack bosun incident 123 because it is normal again.']
            ['hubot', '@alice Trying to ack Bosun incident 123 ...']
            ['hubot', '@alice Yippie. Done.']
          ]

      context "ack multiple incidents", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot ack bosun incidents 123,234 because State is normal again.'
            yield new Promise.delay(wait_time)

        it 'ack bosun alarm', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot ack bosun incidents 123,234 because State is normal again.']
            ['hubot', '@alice Trying to ack Bosun incidents 123,234 ...']
            ['hubot', '@alice Yippie. Done.']
          ]

       context "Other ack and close alarms", ->

        it 'fail to close active bosun alarm'

       context "Fail if unauthorized", ->
        it 'ack bosun incident for unauthorized bob', ->
          @room.user.say('bob', '@hubot ack bosun incident 123 because it is over.').then =>
            expect(@room.messages).to.eql [
              ['bob', '@hubot ack bosun incident 123 because it is over.']
              ['hubot', "@bob Sorry, you're not allowed to do that. You need the 'bosun' role."]
            ]

  context "silences", ->

    context "show silences", ->

      context "show silences for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot show bosun silences'
            yield new Promise.delay(wait_time)

        it 'show bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot show bosun silences']
            ['hubot', '@alice Retrieving Bosun silences ...']
            ['hubot', '@alice Yippie. Done.']
            ['hubot', '@alice So, there are currently 2 active silences in Bosun.']
            ['hubot', "@alice Silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7 from 2016-07-04 15:18:03 UTC until 2016-07-04 16:18:03 UTC for tags host=cake,service=lukas and alert '' because Reboot"]
            ['hubot', "@alice Silence dd406bdce72df2e8c69b5ee396126a7ed8f3bf44 from 2016-07-04 15:16:18 UTC until 2016-07-04 16:16:18 UTC for tags host=muffin,service=lukas and alert 'test.lukas' because Deployment"]
          ]

       context "Fail if unauthorized", ->

        it 'show bosun silences for unauthorized bob', ->
          @room.user.say('bob', '@hubot show bosun silences').then =>
            expect(@room.messages).to.eql [
              ['bob', '@hubot show bosun silences']
              ['hubot', "@bob Sorry, you're not allowed to do that. You need the 'bosun' role."]
            ]

    context "set|test silences", ->

      context "test silence with alert and tags for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot test bosun silence for alert=test.lukas,host=muffin,service=lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'test bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot test bosun silence for alert=test.lukas,host=muffin,service=lukas for 1h because Deployment.']
            ['hubot', "@alice Trying to test Bosun silence for alert 'test.lukas' and tags {host:muffin,service:lukas} for 1h ..."]
            ['hubot', '@alice Yippie. Done. That alarm will work.']
          ]

      context "test silence with alert only for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot test bosun silence for alert=test.lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'test bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot test bosun silence for alert=test.lukas for 1h because Deployment.']
            ['hubot', "@alice Trying to test Bosun silence for alert 'test.lukas' for 1h ..."]
            ['hubot', '@alice Yippie. Done. That alarm will work.']
          ]

      context "test silence with tags only for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot test bosun silence for host=muffin,service=lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'test bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot test bosun silence for host=muffin,service=lukas for 1h because Deployment.']
            ['hubot', '@alice Trying to test Bosun silence for tags {host:muffin,service:lukas} for 1h ...']
            ['hubot', '@alice Yippie. Done. That alarm will work.']
          ]

      context "set silence with alert and tags for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot set bosun silence for alert=test.lukas,host=muffin,service=lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'set bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot set bosun silence for alert=test.lukas,host=muffin,service=lukas for 1h because Deployment.']
            ['hubot', "@alice Trying to set Bosun silence for alert 'test.lukas' and tags {host:muffin,service:lukas} for 1h ..."]
            ['hubot', '@alice Yippie. Done. Admire your alarm at http://localhost:18070/silence.']
          ]

      context "set silence with alert only for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot set bosun silence for alert=test.lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'set bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot set bosun silence for alert=test.lukas for 1h because Deployment.']
            ['hubot', "@alice Trying to set Bosun silence for alert 'test.lukas' for 1h ..."]
            ['hubot', '@alice Yippie. Done. Admire your alarm at http://localhost:18070/silence.']
          ]

      context "test silence with tags only for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot set bosun silence for host=muffin,service=lukas for 1h because Deployment.'
            yield new Promise.delay(wait_time)

        it 'set bosun silences', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot set bosun silence for host=muffin,service=lukas for 1h because Deployment.']
            ['hubot', '@alice Trying to set Bosun silence for tags {host:muffin,service:lukas} for 1h ...']
            ['hubot', '@alice Yippie. Done. Admire your alarm at http://localhost:18070/silence.']
          ]

      context "Fail if unauthorized", ->

        it 'set bosun silences for unauthorized bob', ->
          @room.user.say('bob', '@hubot set bosun silence for alert=test.lukas,host=muffin for 1h because Deployment.').then =>
            expect(@room.messages).to.eql [
              ['bob', '@hubot set bosun silence for alert=test.lukas,host=muffin for 1h because Deployment.']
              ['hubot', "@bob Sorry, you're not allowed to do that. You need the 'bosun' role."]
            ]

    context "clear silences", ->

      context "clear silence for authorized user", ->
        beforeEach ->
          co =>
            yield @room.user.say 'alice', '@hubot clear bosun silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7'
            yield new Promise.delay(wait_time)

        it 'clear bosun silence', ->
          expect(@room.messages).to.eql [
            ['alice', '@hubot clear bosun silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7']
            ['hubot', '@alice Trying to clear Bosun silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7 ...']
            ['hubot', '@alice Yippie. Done.']
          ]

       context "Fail if unauthorized", ->

        it 'clear bosun silence for unauthorized bob', ->
          @room.user.say('bob', '@hubot clear bosun silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7').then =>
            expect(@room.messages).to.eql [
              ['bob', '@hubot clear bosun silence 6e89533c74c3f9b74417b37e7cce75c384d29dc7']
              ['hubot', "@bob Sorry, you're not allowed to do that. You need the 'bosun' role."]
            ]




  context "error handling", ->

      it 'Catch errors'

  context "show config", ->

      it 'show bosun config'


class MockAuth
  hasRole: (user, role) ->
    if user.name is 'alice' and role is 'bosun' then true else false

mock_bosun = () ->
  http.createServer((req, resp) ->
      if req.url == '/api/incidents/open' and req.method == 'GET'
        resp.setHeader('Content-Type', 'application/json')
        incidents = [
          {
            Id: 759,
            Subject: 'warning: <no value>',
            Start: 1467363958,
            AlertName: 'test.lukas',
            Tags: null,
            TagsString: '{}',
            CurrentStatus: 'normal',
            WorstStatus: 'warning',
            LastAbnormalStatus: 'warning',
            LastAbnormalTime: 1467367498,
            Unevaluated: false,
            NeedAck: false,
            Silenced: false,
            Actions: [
              {
                User: "lukas",
                Message: "Okay.",
                Time: 1467411397,
                Type: "Acknowledged"
              }
            ]
            Events: [ [Object], [Object] ],
            WarnNotificationChains: [],
            CritNotificationChains: []
          }
          {
            Id: 750,
            Subject: 'warning: <no value>',
            Start: 1467363958,
            AlertName: 'test.lukas',
            Tags: null,
            TagsString: '{}',
            CurrentStatus: 'warning',
            WorstStatus: 'warning',
            LastAbnormalStatus: 'warning',
            LastAbnormalTime: 1467367498,
            Unevaluated: false,
            NeedAck: true,
            Silenced: false,
            Actions: [],
            Events: [ [Object], [Object] ],
            WarnNotificationChains: [],
            CritNotificationChains: []
          }
        ]
        resp.end JSON.stringify incidents

      if req.url == '/api/action' and req.method == 'POST'
        body = ""
        req.on 'data', (chunk) -> body += chunk
        req.on 'end', () ->
          data = JSON.parse body
          unless data.Type is "ack" or data.Type is "close"
            resp.statusCode = 500;
            resp.setHeader('Content-Type', 'text/plain');
            if data.Ids?
              resp.write "map["
              id_errs = ("#{id}:unknown action type: none" for id in data.Ids)
              resp.write "#{id_errs.join ' '}"
              resp.write "]"
          resp.end()

      if req.url == '/api/silence/get' and req.method == 'GET'
        resp.setHeader('Content-Type', 'application/json')
        silences =  {
          "6e89533c74c3f9b74417b37e7cce75c384d29dc7": {
            Start: "2016-07-04T15:18:03.877775182Z",
            End: "2016-07-04T16:18:03.877775182Z",
            Alert: "",
            Tags: {
              host: "cake",
              service: "lukas"
            },
            TagString: "host=cake,service=lukas",
            Forget: true,
            User: "Lukas",
            Message: "Reboot"
          },
          "dd406bdce72df2e8c69b5ee396126a7ed8f3bf44": {
            Start: "2016-07-04T15:16:18.894444847Z",
            End: "2016-07-04T16:16:18.894444847Z",
            Alert: "test.lukas",
            Tags: {
              host: "muffin",
              service: "lukas"
            },
            TagString: "host=muffin,service=lukas",
            Forget: true,
            User: "Lukas",
            Message: "Deployment"
          }
        }
        resp.end JSON.stringify silences

      if req.url.match('/api/silence/set')? and req.method == 'POST'
        body = ""
        req.on 'data', (chunk) -> body += chunk
        req.on 'end', () ->
          data = JSON.parse body
          resp.end()


      if req.url.match('/api/silence/clear.+')? and req.method == 'POST'
        resp.end ""

    )

