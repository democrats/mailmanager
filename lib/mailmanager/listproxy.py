import json
from Mailman import MailList

class MailingListEncoder(json.JSONEncoder):
  def default(self, obj):
    if isinstance(obj, MailList.MailList):
      return {'name': obj.internal_name()}
    return json.JSONEncoder.default(self, obj)

def dumplist(mlist):
  print json.dumps(mlist, True, cls=MailingListEncoder)

def loadlist(mlist, jsonlist):
  newlist = json.loads(jsonlist)
  for attr in newlist:
    print "Setting %s to %s" % (attr, newlist[attr])

