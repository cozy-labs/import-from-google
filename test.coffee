gdata = require 'simple-gdata'

client = gdata('ya29.ngGXmKhW4_SxcymDOJl-_qlEEMQ4MyhomhNmWORNVOxMLeJPYYmJjEowEbe4LrDBfSqtEE4G6amBlQ')


client.getFeed "https://www.google.com/m8/feeds/contacts/default/full/?alt=json", (err, body)->
    console.log(err)
    console.log(JSON.stringify body)
